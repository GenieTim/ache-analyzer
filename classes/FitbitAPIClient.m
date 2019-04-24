classdef FitbitAPIClient
    %FITBITAPICLIENT API client for the FitBit Fitness API
    %   Client to get data on fitness
    
    properties
        config % configuration for the API
        oauthclient % authentication util
        fitnessDataCache % cache 
        fitnessDataCacheName % cache file name
    end
    
    methods
        function obj = FitbitAPIClient()
            %FITBITAPICLIENT Construct an instance of this class
            %   Detailed explanation goes here
            % read configuration
            configFile = fileread('config.json');
            obj.config = jsondecode(configFile).fitbit;
            params = {
                obj.config.callbackURI
                obj.config.callbackSecret
                obj.config.clientId
                obj.config.clientSecret
                obj.config.scopes
            };
            oauthService = OAuth2ServiceInformation(params{:});
            obj.oauthclient = OAuth2Client(oauthService);
            % warmup cache
            obj.fitnessDataCacheName = 'weatherData.xlsx';
            obj.fitnessDataCache = readtable(obj.fitnessDataCacheName);
            if (isempty(obj.fitnessDataCache))
                obj.fitnessDataCache = cell2table(cell(0,3), 'VariableNames', {'time', 'type', 'data'});
            end
        end
        
        function fitness = loadFitnessActivitySummary(obj, time)
            if (~isdatetime(time))
                warning("Parameter time is required to be MATLABs datetime");
            end
            fitness = obj.loadFitnessLocally(time, 'activity');
            if (numel(fitness) == 0)
                fitness = obj.makeRequest(sprintf("https://api.fitbit.com/1/user/-/activities/date/%s.json", string(time, 'yyyy-MM-dd')));
                obj.saveFitnessLocally('activity', time, fitness);
            end
            fitness = jsondecode(fitness);
        end

        function fitness = loadHeartrate(obj, time) 
            if (~isdatetime(time))
                warning("Parameter time is required to be MATLABs datetime");
            end
            fitness = obj.loadFitnessLocally(time, 'heartrate');
            if (numel(fitness) == 0)
                fitness = obj.makeRequest(sprintf("https://api.fitbit.com/1/user/-/activities/heart/date/%s/1d/1min.json", string(time, 'yyyy-MM-dd')));
                obj.saveFitnessLocally('heartrate', time, fitness)
            end
            fitness = jsondecode(fitness);
        end

        function [fitness] = loadFitnessLocally(obj, time, type)
        %FINDROW find the row in the fitness data where longitude etc. match
            if (~isdatetime(time))
                warning("Parameter time is required to be MATLABs datetime");
            end
            matchingType = obj.fitnessData(obj.fitnessData.type == type, :);
            fitness = matchingType(matchingType.time == time,:);
        end

        function [] = saveFitnessLocally(obj, type, time, data)
        %SAVEFITNESSLOCALLY save the wether from the api into a local xlsx file to
        %reduce number of calls
            if (~isdatetime(time))
                warning("Parameter time is required to be MATLABs datetime");
            end
            obj.fitnessData = [obj.fitnessData; {type, time, data}];
            writetable(fitnessData, 'fitnessData.xlsx');
        end

        function [data] = makeRequest(obj, url)
        %MAKEGETREQUEST Make a GET HTTP request to the specified url            
            data = obj.oauthclient.makeGetRequest(url);
        end

    end
end

