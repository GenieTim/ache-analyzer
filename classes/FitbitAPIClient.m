classdef FitbitAPIClient < DataProviderInterface
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
            %   Use FitbitAPIClient for communication with FitBit API
            % read configuration
            configFile = fileread('config.json');
            obj.config = jsondecode(configFile);
            obj.config = obj.config.fitBit;
            % setup config for oauthclient
            params = {
                obj.config.callbackURI
                obj.config.callbackSecret
                obj.config.authorizationURI
                obj.config.refreshTokenURI
                obj.config.clientID
                obj.config.clientSecret
                obj.config.scopes
                'token' % we choose implicit code grant flow
            };
            % https://dev.fitbit.com/build/reference/web-api/oauth2/
            oauthService = OAuth2ServiceInformation(params{:});
            % construct the oauth client, config dependent
            if (propAvailable(obj.config, 'accessToken'))
                obj.oauthclient = OAuth2Client(oauthService, 'Bearer', obj.config.accessToken);                
            else
                obj.oauthclient = OAuth2Client(oauthService);
            end
            % warmup cache
            obj.fitnessDataCacheName = 'fitnessData.xlsx';
            if (isfile(obj.fitnessDataCacheName))
                obj.fitnessDataCache = readtable(obj.fitnessDataCacheName);
            end
            if (isempty(obj.fitnessDataCache))
                obj.fitnessDataCache = cell2table(cell(0,3), 'VariableNames', {'time', 'type', 'data'});
            end
        end
        
        function fitness = loadFitnessActivitySummary(obj, time)
            type = 'activity';
            if (~isdatetime(time))
                warning("Parameter time is required to be MATLABs datetime");
            end
            fitness = obj.loadFitnessLocally(time, type);
            if (numel(fitness) == 0)
                fitness = obj.makeRequest(sprintf("https://api.fitbit.com/1/user/-/activities/date/%s.json", string(time, 'yyyy-MM-dd')));
                if (~isempty(fitness))
                    % do not forget to save cache result in the end like so:
                    % obj.flushCache(); 
                    obj.fitnessDataCache = [obj.fitnessDataCache; {time, type, jsonencode(fitness)}];
                end
            end
            % move interesting data to toplevel, we can only process 1
            % level deep struct data
            fitness = fitness.summary;
            fitness.distances = fitness.distances.total;
        end

        function heartrate = loadHeartrate(obj, time) 
            type = 'heartrate';
            if (~isdatetime(time))
                warning("Parameter time is required to be MATLABs datetime");
            end
            heartrate = obj.loadFitnessLocally(time, type);
            if (numel(heartrate) == 0)
                heartrate = obj.makeRequest(sprintf("https://api.fitbit.com/1/user/-/activities/heart/date/%s/1d/1min.json", string(time, 'yyyy-MM-dd')));                
                if (~isempty(heartrate))
                    obj.fitnessDataCache = [obj.fitnessDataCache; {time, type, jsonencode(heartrate)}];
                    % do not forget to save cache result in the end like so:
                    % obj.flushCache();
                end
            end
            % move interesting data to toplevel, we can only process 1
            % level deep struct data
            allHeartRates = zeros(1, numel(heartrate.("activities-heart-intraday").dataset));
            for i = 1:numel(allHeartRates)
                allHeartRates(i) = heartrate.("activities-heart-intraday").dataset(i).value;
            end
            % ok, actually, we do a whole new struct
            newHeartRate = struct;
            newHeartRate.maxHeartRate = max(allHeartRates);
            newHeartRate.minHeartRate = min(allHeartRates);
            newHeartRate.meanHeartRate = mean(allHeartRates);
            newHeartRate.medianHeartRate = median(allHeartRates);
            heartrate = newHeartRate;
        end

        function [] = flushCache(obj)
        %SAVEFITNESSLOCALLY save the wether from the api into a local xlsx file to
        %reduce number of calls
            writetable(obj.fitnessDataCache, obj.fitnessDataCacheName);
        end

        function data = getDailyData(obj, from, to)
        %GETDAILYDATA returns a table with all the data for datetime days
        %between from and to.
            if (from > to)
                error("Invalid inputs. Can only serve data from datetime, only if datetime from < to.");
            end
            dateSequence = from:to;
            % TODO: enhance software design , do not do everything explicit
            % for all the possible data
            heartRateData = cell(1,numel(dateSequence));
            activityData = cell(1,numel(dateSequence));
            for i = 1:numel(dateSequence)
                heartRateData{i} = obj.loadHeartrate(dateSequence(i));
                heartRateData{i}.time = dateSequence(i);
                activityData{i} = obj.loadFitnessActivitySummary(dateSequence(i));
                activityData{i}.time = dateSequence(i);
            end
            heartRateData = struct2table(heartRateData);
            activityData = struct2table(activityData);
            data = join(heartRateData, activityData);
        end
        
    end
    
    methods (Access=protected)
        function [fitness] = loadFitnessLocally(obj, time, type)
        %FINDROW find the row in the fitness data where longitude etc. match
            if (~isdatetime(time))
                warning("Parameter time is required to be MATLABs datetime");
            end
            if (isempty(obj.fitnessDataCache))
                fitness = []; return;
            end
            matchingType = obj.fitnessDataCache(obj.fitnessDataCache.type == type, :);
            fitness = matchingType(matchingType.time == time,:);
            fitness = jsondecode(fitness);
        end

        function [data] = makeRequest(obj, url)
        %MAKEGETREQUEST Make a GET HTTP request to the specified url            
            data = obj.oauthclient.makeGetRequest(url);
        end

    end
end

