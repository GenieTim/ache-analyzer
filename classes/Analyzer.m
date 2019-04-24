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
            obj.objectiveDataSet = readtable('headacheData.xlsx');
            
            % use passed variables
            for i = 1:nargin
                obj = obj.addDataSet(varargin{i});
            end
        end
        
        function obj = addDataSet(obj,dataSet)
            %ADDDATASET Add a collection of data to be analysed
            %   dataSet shall be table I guess
            if (~istable(dataSet))
                warning("Dataset passed is not a table. Discarding...");
            else
                obj.dataSets{end} = dataSet;                
            end
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

