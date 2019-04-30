classdef Analyzer
    %ANALYZER The Analyzer is the main class collecting data for analysis
    %   Use this class to dynamically add & remove datasets and finally
    %   retrieve the results
    
    properties
        dataSets
        objectiveDataSet
    end
    
    methods
        function obj = Analyzer(varargin)
            %ANALYZER Construct an instance of this class
            %   Objective data set is loaded from headacheData.xlsx
            % load objective
            objectiveDataSet = readtable('headacheData.xlsx');
            if (~ismember('time', objectiveDataSet.Properties.VariableNames))
                error("headacheData.xlsx needs a column titled 'time'.");
            end
            objectiveDataSet.time = datetime(objectiveDataSet.time);
            obj.objectiveDataSet = sortrows(objectiveDataSet, 'time');
            obj.dataSets = {};
            
            % use passed variables
            for i = 1:nargin
                obj = obj.addDataSet(varargin{i});
            end
        end
        
        function obj = addDataByDataProvider(obj, provider)
            %ADDDATAPROVIDER add a DataProviderInterface provider from
            %which to take data
            if (~isa(provider, 'DataProviderInterface'))
                error('Provider has to implement DataProviderInterface');
            end
            
            from = makeDateMidday(obj.objectiveDataSet.time(1));
            to =  makeDateMidday(obj.objectiveDataSet.time(end));
            obj = obj.addDataSet(provider.getDailyData(from, to));
            provider.flushCache();
        end
        
        function obj = addDataSet(obj,dataSet)
            %ADDDATASET Add a collection of data to be analysed
            %   dataSet shall be table I guess
            if (~istable(dataSet))
                warning("Dataset passed is not a table. Discarding...");
                return;
            end
            if (~ismember('time', dataSet.Properties.VariableNames))
                warning("Dataset does not have property 'time'. Discarding...");
                return;
            end
            % TODO: prefix table variable names
           obj.dataSets{numel(obj.dataSets) + 1} = dataSet;       
        end
        
        function [loadings,scores,vexpZ,tsquared,vexpX,mu] = runPrincipalComponentAnalysis(obj)
            %RUNPRINCIPALCOMPONENTANALYSIS Do analyse. Now.
            dataTable = obj.objectiveDataSet;
            for i = 1:numel(obj.dataSets)
                dataTable = join(dataTable, obj.dataSets{i});
            end
            
            [loadings,scores,vexpZ,tsquared,vexpX,mu] = pca(dataTable);
            biplot(loadings(:,1:3),'scores',scores(:,1:3),'varlabels',dataTable.Properties.VariableNames);
        end
    end
end

