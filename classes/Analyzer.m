classdef Analyzer
    %ANALYZER The Analyzer is the main class collecting data for analysis
    %   Use this class to dynamically add & remove datasets and finally
    %   retrieve the results
    % Checkout
    % https://www.mathworks.com/help/stats/dimensionality-reduction.html 
    % for more ideas
    
    properties
        dataSets
        objectiveDataSet
        responseVariable
    end
    
    methods
        function obj = Analyzer(varargin)
            %ANALYZER Construct an instance of this class
            %   Objective data set is loaded from headacheData.xlsx
            % pseudo-config:
            inputFileName = 'headacheData.xlsx';
            obj.responseVariable = 'dolor';
            % load objective
            objectiveDataSet = readtable(inputFileName);
            if (~ismember('time', objectiveDataSet.Properties.VariableNames))
                error(strcat(inputFileName, " needs a column titled 'time'."));
            end
            if (~ismember(obj.responseVariable, objectiveDataSet.Properties.VariableNames))
                error(strcat(inputFileName, " needs a column titled '", obj.responseVariable, "'."));
            end
            objectiveDataSet.time = datetime(objectiveDataSet.time);
            obj.objectiveDataSet = sortrows(objectiveDataSet, 'time');
            obj.dataSets = {};
            
            % use passed variables
            for i = 1:nargin
                obj = obj.addDataSet(varargin{i});
            end
        end
        
        function obj = fillObjectiveData(obj)
            from = makeDateMidday(obj.objectiveDataSet.time(1));
            to =  makeDateMidday(obj.objectiveDataSet.time(end));
            dateSequence = from:to;
            for i = 1:numel(dateSequence)
                time = dateSequence(i);
                matchDate = obj.objectiveDataSet(ismember(datestr(obj.objectiveDataSet.time, 'dd/mm/yyyy'), string(datestr(time, 'dd/mm/yyyy'))), :);
                if (isempty(matchDate))
                    newRow = struct();
                    newRow.time = time;
                    newRow.dolor = 0;
                    obj.objectiveDataSet = [obj.objectiveDataSet; struct2table(newRow)];
                end
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
            %RUNPRINCIPALCOMPONENTANALYSIS Do analysis using PCA
            dataTable = obj.mergeTables();
            
            % TODO: filter non-numeric data first
            [loadings,scores,vexpZ,tsquared,vexpX,mu] = pca(table2array(dataTable));
            biplot(loadings(:,1:3),'scores',scores(:,1:3),'varlabels',dataTable.Properties.VariableNames);
        end
        
        function tree = runDecisionTree(obj)
            %RUNDECISIONTREE Do analysis using decision tree 
            %TODO: refactor not to require this arbitrary nr. of
            %re-simplifications
            dataTable = simplifyTable(obj.mergeTables());
            dataTable = simplifyTable(dataTable);
            dataTable = simplifyTable(dataTable);
            tree = fitctree(dataTable, obj.responseVariable);
            view(tree,'Mode','graph')
        end
        
        function [merged] = mergeTables(obj)
            %MERGETABLES merge/join all data sets together into one table
            merged = obj.objectiveDataSet;
            merged.dateStr = datestr(datenum(merged.time), 'dd/mm/yyyy');
            for i = 1:numel(obj.dataSets)
                setToAdd = obj.dataSets{i};
                setToAdd.dateStr = datestr(datenum(setToAdd.time), 'dd/mm/yyyy');
                merged = join(merged, setToAdd, 'Keys', 'dateStr');
                %innerjoin(merged, obj.dataSets{i}, 'LeftKeys', 'time', 'RightKeys', 'time');
            end            
            % set the predictor variable where necessary
            %indices = isnan(table2array(merged(:, obj.responseVariable)));
            %merged(indices, obj.responseVariable) = zeros(1, sum(indices));
            merged.dolor(isnan(merged.dolor)) = 0;
        end
    end
end

