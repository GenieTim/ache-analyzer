classdef OAuth2Client < handle
    %OAUTH2CLIENT Generic OAuth2 Client to retrieve an authentication token
    %   Use class OAuth2ServiceInformation to pass the corresponding
    %   configurations
    
    properties
        service_information
        autorization_code_context
        access_token
        access_token_birth
        refresh_token
        token_type
    end
    
    methods
        function obj = OAuth2Client(service_information, token_type, access_token)
            %OAUTH2CLIENT Construct an instance of this class
            %   Argument access_token is optional and can be set e.g. for
            %   implicit authentication flows
            obj.service_information = service_information;
            
            
            if (nargin > 1)
                obj.token_type = token_type;
            else 
                obj.token_type = 'Bearer';
            end
            if (nargin > 2)
                obj.access_token = access_token;
                obj.access_token_birth = datetime();                
            end
        end
        
        function accessToken = getAccessToken(obj)
            %GETACCESSTOKEN Get the access token to be used by simple
            %requests
            
            % assume the access token is valid when it is current
            if (obj.isAccessTokenCurrent())
                accessToken = obj.access_token;
                return;
            end
            % otherwise, we have to request a new one
            if (obj.refresh_token) 
                obj = obj.refreshAccessToken();
            else
                obj = obj.requestAccessToken();
            end
            accessToken = obj.access_token;
        end
        
        function obj = requestAccessToken(obj)
            %REQUESTACCESSTOKEN get a new access & refresh token 
            disp("Requesting Access Token. You might need to interact...");
            data = [...
             '?redirect_uri=', obj.service_information.redirectURI,... 
             '&client_id=', obj.service_information.client_id,...
             '&client_secret=', obj.service_information.client_secret,...
             '&grant_type=', 'authorization_code',...
             '&code=', obj.service_information.redirectCode,...
             '&scope=', obj.service_information.scopes,...
             '&response_type=', obj.service_information.response_type];
                % GET
             url = strcat(obj.service_information.authorizationURI, join(data, ''));
             web(url, '-browser');
             response = struct;
             % save respective response values
             requiredFields = {'expires_in', 'refresh_token', 'access_token', 'token_type'};
             for i = 1:numel(requiredFields)
                 response.(requiredFields{i}) = input(strcat("Please enter the value of ", requiredFields{i}, " (strings in ''):"));
             end
             obj.service_information.tokenMaxAge = response.expires_in / 60;
             obj.refresh_token = response.refresh_token;
             obj.access_token = response.access_token;
             obj.token_type = response.token_type;
             obj.access_token_birth = datetime();
        end
        
        function obj = refreshAccessToken(obj)
            %REFRESHACCESSTOKEN Refresh the token
            options = weboptions('HeaderFields', 'Authorization', obj.service_information.authorizationHeader); % 'ContentType','application/x-www-form-urlencoded'
            data = [...
             'refresh_token=', obj.refresh_token,...
             '&grant_type=', 'refresh_token',...
             '&expires_in=', 28800];
             % POST
             response = webwrite(obj.service_information.refreshTokenURI,data,options);
             response = jsondecode(response);
             % save respective response values if successfull
             % measure of successfull is that we rely on having a property
             % we could also ask the api if the refresh token is still
             % current
             if (isfield(response, 'expires_in') || isprop(response, 'expires_in'))
                 obj.service_information.tokenMaxAge = response.expires_in / 60;
                 obj.refresh_token = response.refresh_token;
                 obj.access_token = response.access_token;
                 obj.access_token_birth = datetime();
             else
             % otherwise request new access token
                 obj = obj.requestAccessToken();
             end
        end
        
        function current = isAccessTokenCurrent(obj)
            %ISACCESSTOKENCURRENT Check whether the access token ist still
            %timely fine
            if (isempty(obj.access_token) || isempty(obj.access_token_birth)) 
                disp("empty")
                current = 0;
            else
                age = datetime() - obj.access_token_birth;
                current = minutes(age) < obj.service_information.tokenMaxAge;
                fprintf("Age %f, ergo %d\n", minutes(age), current);
            end
        end
        
        function [data] = makeGetRequest(obj, url)
            %MAKEGETREQUEST Make a GET HTTP request to the specified url,
            %authenticated.
            % TODO: fix issues with MATLAB class type (handle vs. ...)
            accessToken = obj.getAccessToken();
            authorizationHeader = strcat(obj.token_type, " ", accessToken);
            headerFields = {'Authorization', authorizationHeader{:}};
            options = weboptions('HeaderFields', headerFields, 'ContentType','json');
            data = webread(url, options);
        end
    end
end

