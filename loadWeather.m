% TODO: move to a class to reduce usage of global variables
function [weather] = loadWeather(long, lat, time)
%LOADWEATHER Load the weather data
%   Detailed explanation goes here
    setup();
    weather = loadWeatherLocally(long, lat, time);
    if (numel(weather) == 0)
        weather = loadWeatherOnline(long, lat, time);
    end
    weather = jsondecode(weather);
end

function [weather] = loadWeatherLocally(long, lat, time)
%FINDROW find the row in the weather data where longitude etc. match
    global weatherData;
    
    matchingLong = weatherData(weatherData.long == long,:);
    matchingLat = matchingLong(matchingLong.lat == lat,:);
    weather = matchingLat(matchingLat.time == time,:);
end

function [] = saveWeatherLocally(long, lat, time, weather)
%SAVEWEATHERLOCALLY save the wether from the api into a local xlsx file to
%reduce number of calls
    global weatherData;
    
    weatherData = [weatherData; {long, lat, time, weather}];
    writetable(weatherData, 'weatherData.xlsx');
end

function [weather] = loadWeatherOnline(long lat, time)
%LOADWEATHERONLINE load the weather from an API endpoint
    global config;
    apiSecret = config.darkSky.apiSecret;
    url = sprintf(config.darkSky.apiURL, apiSecret, lat, long, time);
    weather = webread(url);
    % cache result
    saveWeatherLocally(long, lat, time, weather);
end

function [] = setup()
%SETUP Set up this weather loader by setting our cache/global variables
    global config;
    if (isempty(config))
        file = fileread('config.json');
        config = jsondecode(file);
    end
    global weatherData;
    if (isempty(weatherData))
        weatherData = readtable('weatherData.xlsx');
    end
end
