classdef DarkSkyAPIClient
    %DARKSKYAPICLIENT API client for the dark sky weather API
    %   Client to get data on weather
    
    properties
        config % configuration for the API
        weatherDataCache % cache 
        weatherDataCacheName % cache file name
    end
    
    methods
        function obj = DarkSkyAPIClient()
            %DARKSKYAPICLIENT Construct an instance of this class
            %   Detailed explanation goes here
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
            weather = jsondecode(weather);
        end

        function [weather] = loadWeatherLocally(obj, long, lat, time)
        %FINDROW find the row in the weather data where longitude etc. match
            if (~isdatetime(time))
                warning("Parameter time is required to be MATLABs datetime");
            end
            if (isempty(obj.weatherDataCache))
                weather = []; return;
            end
            matchingLong = obj.weatherDataCache(obj.weatherDataCaache.long == long,:);
            matchingLat = matchingLong(matchingLong.lat == lat,:);
            weather = matchingLat(matchingLat.time == time,:);
        end

        function [] = saveWeatherLocally(obj, long, lat, time, weather)
        %SAVEWEATHERLOCALLY save the wether from the API into a local xlsx file to
        %reduce number of calls to API
            if (~isdatetime(time))
                warning("Parameter time is required to be MATLABs datetime");
            end
            weatherData = [obj.weatherDataCache; {long, lat, time, weather}];
            writetable(weatherData, obj.weatherDataCacheName);
        end

        function [weather] = loadWeatherOnline(obj, long, lat, time)
        %LOADWEATHERONLINE load the weather from an API endpoint
            if (~isdatetime(time))
                warning("Parameter time is required to be MATLABs datetime");
            end
            url = sprintf(obj.config.apiURL, obj.config.apiSecret, lat, long, time);
            weather = webread(url);
            % cache result
            saveWeatherLocally(long, lat, time, weather);
        end
    end
end

