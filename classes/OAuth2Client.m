classdef OAuth2Client
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
        function obj = OAuth2Client(service_information)
            %OAUTH2CLIENT Construct an instance of this class
            %   Detailed explanation goes here
            obj.service_information = service_information;
        end
        
        function [accessToken, obj] = getAccessToken(obj)
            %GETACCESSTOKEN Get the access token to be used by simple
            %requests
            
            % assume the access token is valid when it is current
            if (isAccessTokenCurrent())
                accessToken = obj.access_token;
                return;
            end
            % otherwise, we have to request a new one
            if (obj.refresh_token) 
                obj = requestRefreshToken();
            else
                obj = requestAccessToken();
            end
            accessToken = obj.access_token;
        end
        
        function obj = requestAccessToken(obj)
            %REQUESTACCESSTOKEN get a new access & refresh token 
            options = weboptions('HeaderFields', obj.service_information.authorizationHeader, 'ContentType','application/x-www-form-urlencoded');
            data = [...
             'redirect_uri=', obj.service_information.redirectURI,... 
             '&client_id=', obj.service_information.client_id,...
             '&client_secret=', obj.service_information.client_secret,...
             '&grant_type=', 'authorization_code',...
             '&code=', obj.service_information.redirectCode];
                % POST
             response = webwrite(obj.service_information.authorizationURI,data,options);
             response = jsondecode(response);
             % save respective response values
             obj.service_information.tokenMaxAge = response.expires_in / 60;
             obj.refresh_token = response.refresh_token;
             obj.access_token = response.access_token;
             obj.access_token_birth = datetime();
        end
        
        function obj = refreshAccessToken(obj)
            %REFRESHACCESSTOKEN Refresh the token
            options = weboptions('HeaderFields', obj.service_information.authorizationHeader, 'ContentType','application/x-www-form-urlencoded');
            data = [...
             'refresh_token=', obj.refresh_token,...
             '&grant_type=', 'refresh_token',...
             '&expires_in=', 28800];
             % POST
             response = webwrite(obj.service_information.refreshTokenURI,data,options);
             response = jsondecode(response);
             % save respective response values if successfull
             % measure of successfull is that we rely on having a property
             if (isprop(response, 'expires_in'))
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
            age = datetime() - obj.access_token_birth;
            current = minutes(age) < obj.service_information.tokenMaxAge;
        end
        
        function [data] = makeGetRequest(obj, url)
            %MAKEGETREQUEST Make a GET HTTP request to the specified url,
            %authenticated.
            % TODO: fix issues with MATLAB class type (handle vs. ...)
            accessToken = obj.getAccessToken();
            headerFields = {'Authorization', [strcat(obj.token_type, " "), accessToken]};
            options = weboptions('HeaderFields', headerFields, 'ContentType','json');
            data = webread(url, options);
        end
    end
end

