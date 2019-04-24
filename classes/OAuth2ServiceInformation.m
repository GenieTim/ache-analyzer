classdef OAuth2ServiceInformation
    %OAUTH2SERVICEINFORMATION class to assemble all Oauth 2 relevant config
    %   This class serves as configuration interface for the OAuth2Client
    
    properties
        redirectURI
        redirectCode
        authorizationURI
        refreshTokenURI
        client_id
        client_secret
        scopes
        authorizationHeader
        tokenMaxAge
    end
    
    methods
        function obj = OAuth2ServiceInformation(redirectURI, redirectCode, client_id, client_secret, scopes, tokenMaxAge)
            %OAUTH2SERVICEINFORMATION Construct an instance of this class
            %   Detailed explanation goes here
            obj.redirectCode = redirectCode;
            obj.redirectURI = redirectURI;
            obj.client_id = client_id;
            obj.client_secret = client_secret;
            obj.scopes = scopes;
            obj.authorizationHeader = strcat("Basic ", base64encode(sprintf('%s:%s', self.client_id, self.client_secret)));
            if (nargs < 7)
                tokenMaxAge = 10; % in minutes
            end
            obj.tokenMaxAge = tokenMaxAge;
        end
    end
end

