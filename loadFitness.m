% TODO: move to a class to reduce usage of global variables and introduce a state
function fitness = loadFitnessActivitySummary(time)
    setup();
    fitness = loadFitnessLocally(time, 'activity');
    if (numel(fitness) == 0)
        % TODO: format time: yyyy-MM-dd
        fitness = makeRequest(sprintf("https://api.fitbit.com/1/user/-/activities/date/%s.json", time));
        saveFitnessLocally('activity', time, fitness);
    end
    fitness = jsondecode(fitness);
end

function fitness = loadHeartrate(time) 
    setup();
    fitness = loadFitnessLocally(time, 'heartrate');
    if (numel(fitness) == 0)
        % TODO: format time: yyyy-MM-dd
        fitness = makeRequest(sprintf("https://api.fitbit.com/1/user/-/activities/heart/date/%s/1d/1min.json", time));
        saveFitnessLocally('heartrate', time, fitness)
    end
    fitness = jsondecode(fitness);
end

function [fitness] = loadFitnessLocally(time, type)
%FINDROW find the row in the fitness data where longitude etc. match
    global fitnessData;
    
    matchingType = fitnessData(fitnessData.type == type, :);
    fitness = matchingType(matchingType.time == time,:);
end

function [] = saveFitnessLocally(type, time, data)
%SAVEFITNESSLOCALLY save the wether from the api into a local xlsx file to
%reduce number of calls
    global fitnessData;
    
    fitnessData = [fitnessData; {type, time, data}];
    writetable(fitnessData, 'fitnessData.xlsx');
end

function [data] = makeRequest(url)
    % TODO: check login/authentication etc.
    data = webread(url);
end


function [] = setup()
%SETUP Set up this fitbit loader by setting our cache/global variables
    global config;
    if (isempty(config))
        file = fileread('config.json');
        config = jsondecode(file);
    end
    % TODO: authenticate if necessary with FitBit service

    global fitnessData;
    if (isempty(fitnessData))
        fitnessData = readtable('fitnessData.xlsx');
    end
end
