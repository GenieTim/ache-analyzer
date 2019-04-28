classdef DataProviderInterface < handle
    %DATAPROVIDERINTERFACE Abstract class for data provider for Analyzer
    %   Provides the basic interface needed for the class Analyzer
    
    properties
        
    end
    
    methods(Abstract)
        flushCache(obj)
        %FLUSHCACHE writes the cache for later usage after all data was
        %loaded finally
        data = getDailyData(obj, from, to)
        %GETDAILYDATA returns a table with all the data for datetime days
        %between from and to. Each table needs the column "time" in order
        %to join properly later
    end
end

