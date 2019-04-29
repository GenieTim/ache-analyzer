classdef DarkSkyAPIClient < DataProviderInterface
    %DARKSKYAPICLIENT API client for the dark sky weather API
    %   Client to get data on weather
    
    properties
        config % configuration for the API
        weatherDataCache % cache 
        weatherDataCacheName % cache file name
        long % longitude of position for which to load data
        lat % latitude of position for which to load data
    end
    
    methods
        function obj = DarkSkyAPIClient(long, lat)
            %DARKSKYAPICLIENT Construct an instance of this class
            %   Detailed explanation goes here
            if (nargin == 2)
                obj.long = long;
                obj.lat = lat;
            end
            % read configuration
            configFile = fileread('config.json');
            obj.config = jsondecode(configFile);
            obj.config = obj.config.darkSky;
            % warmup cache
            obj.weatherDataCacheName = 'weatherData.xlsx';
            if (isfile(obj.weatherDataCacheName))
                obj.weatherDataCache = readtable(obj.weatherDataCacheName);
            end
            if (isempty(obj.weatherDataCache))
                obj.weatherDataCache = cell2table(cell(0,4), 'VariableNames', {'long', 'lat', 'time', 'weather'});
            end
        end
        
        function [weather] = loadWeather(obj, long, lat, time)
        %LOADWEATHER Load the weather data
        %   Detailed explanation goes here
            if (~isdatetime(time))
                warning("Parameter time is required to be MATLABs datetime");
            end
            weather = obj.loadWeatherLocally(long, lat, time);
            if (numel(weather) == 0)
                weather = obj.loadWeatherOnline(long, lat, time);
            end
            if (isstring(weather))
                weather = jsondecode(weather);
            end
        end

        function [] = flushCache(obj)
        %FLUSHCACHE save the wether from the API into a local xlsx file to
        %reduce number of calls to API
            writetable(obj.weatherDataCache, obj.weatherDataCacheName);
        end
        
        function data = getDailyData(obj, from, to)
        %GETDAILYDATA returns a table with all the data for datetime days
        %between from and to.           
            if (from > to)
                error("Invalid inputs. Can only serve data from datetime, only if datetime from < to.");
            end
            dateSequence = from:to;
            data = cell(1,numel(dateSequence));
            for i = 1:numel(dateSequence)
                newData = obj.loadWeather(obj.long, obj.lat, dateSequence(i));
                if (propAvailable(newData, 'daily'))
                    data{i} = newData.daily.data;
                elseif (propAvailable(newData, 'currently'))
                    data{i} = newData.currently.data;
                else
                    warning('Failed to interpret weather data at %d, %d for %s.', obj.long, obj.lat, string(dateSequence(i), 'dd.MM.yyyy HH:mm'));
                end
                data{i}.time = dateSequence(i);
            end
            data = cellStructArrayToTable(data);
        end
    end

    methods (Access=protected)
        function [weather] = loadWeatherLocally(obj, long, lat, time)
        %FINDROW find the row in the weather data where longitude etc. match
            if (~isdatetime(time))
                warning("Parameter time is required to be MATLABs datetime");
            end
            if (isempty(obj.weatherDataCache))
                weather = []; return;
            end
            matchingLong = obj.weatherDataCache(obj.weatherDataCache.long == long,:);
            matchingLat = matchingLong(matchingLong.lat == lat,:);
            weather = matchingLat(matchingLat.time == time,:);
        end

        function [weather] = loadWeatherOnline(obj, long, lat, time)
        %LOADWEATHERONLINE load the weather from an API endpoint
            if (~isdatetime(time))
                warning("Parameter time is required to be MATLABs datetime");
            end
            url = sprintf(obj.config.apiURL, obj.config.apiSecret, lat, long, int64(posixtime(time)));
            try
                weather = webread(url);
            catch exception
                % save what we have before giving up on HTTP errors 
                % (e.g. API contingent used up)
                obj.flushCache();
                rethrow(exception);
            end
            obj.weatherDataCache = [obj.weatherDataCache; {long, lat, time, jsonencode(weather)}];
            % do not forget to save cache result in the end like so:
            % obj.flushCache();
        end
    end
end

