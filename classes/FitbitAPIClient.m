classdef FitbitAPIClient < DataProviderInterface
    %FITBITAPICLIENT API client for the FitBit Fitness API
    %   Client to get data on fitness
    
    properties
        config % configuration for the API
        oauthclient % authentication util
        fitnessDataCache % cache 
        fitnessDataCacheName % cache file name
        cacheDirty % flag to set if the cache has to be saved in the end
    end
    
    methods
        function obj = FitbitAPIClient()
            %FITBITAPICLIENT Construct an instance of this class
            %   Use FitbitAPIClient for communication with FitBit API
            obj.cacheDirty = 0;
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
            obj.fitnessDataCacheName = 'fitnessData.csv'; % csv,  not xlsx, as xlsx has a char limit reached by these data
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
                    obj.cacheDirty = 1;
                end
            end
            % move interesting data to toplevel, we can only process 1
            % level deep struct data
            fitness = fitness.summary;
            distanceForActivity = [fitness.distances.distance];
            fitness.distances = max(distanceForActivity); % max = total :P. 
            % If looking for separate/per activity: check out fitness.distances.activity
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
                    obj.cacheDirty = 1;
                    % do not forget to save cache result in the end like so:
                    % obj.flushCache();
                end
            end
            % move interesting data to toplevel, we can only process 1
            % level deep struct data
            allHeartRates = zeros(1, numel(heartrate.("activities_heart_intraday").dataset));
            for i = 1:numel(allHeartRates)
                allHeartRates(i) = heartrate.("activities_heart_intraday").dataset(i).value;
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
            if (obj.cacheDirty)
                writetable(obj.fitnessDataCache, obj.fitnessDataCacheName);
                obj.cacheDirty = 0;
            end
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
            heartRateData = cellStructArrayToTable(heartRateData);
            activityData = cellStructArrayToTable(activityData);
            data = join(heartRateData, activityData);
        end
        
    end
    
    methods (Access=protected)
        function [fitness] = loadFitnessLocally(obj, time, type)
        %FINDROW find the row in the fitness data where datetime & type match
            if (~isdatetime(time))
                warning("Parameter time is required to be MATLABs datetime");
            end
            if (isempty(obj.fitnessDataCache))
                fitness = []; return;
            end
            matchingType = obj.fitnessDataCache(ismember(obj.fitnessDataCache.type(:), type), :);
            if (isempty(matchingType))
                fitness = []; return;                
            end
            % let's not compare the time
            fitness = matchingType(ismember(datestr(datenum(matchingType.time, 'dd.mm.yy'), 'dd/mm/yyyy'), string(datestr(time, 'dd/mm/yyyy'))), :);
            if (isempty(fitness))
                fitness = []; return; 
            end
            % access raw data. We do not yet haven an index for data -> 3
            fitness = jsondecode(char(fitness{1,3}));
            if (iscell(fitness))
                fitness = jsondecode(string(fitness));
            end
        end

        function [data] = makeRequest(obj, url)
        %MAKEGETREQUEST Make a GET HTTP request to the specified url
            % try. if we fail, we save what we have before crashing
            pause(randi([0, 60], 1, 1)); % sleep to calm down fitbit API
            try
                data = obj.oauthclient.makeGetRequest(url);
            catch exception
                obj.flushCache();
                rethrow(exception);
            end
            % we should save cache from time to time anyways
            if (randi([0, 20], 1, 1) > 16)
                obj.flushCache();                
            end
        end

    end
end

