function [t] = cellStructArrayToTable(cellArrayOfStruct)
%CELLSTRUCTARRAYTOTABLE Convert a cell array full of structs to a table
%   All fields will be made uniform
    % detect all fields
    if (~iscell(cellArrayOfStruct))
        warning("Invalid input passed.");
    end
    
    fields = {};
    for i = 1:numel(cellArrayOfStruct)
        if (~isstruct(cellArrayOfStruct{i}))
            warning("Invalid input passed on index %d.", i);            
        end
        fields = [fields, fieldnames(cellArrayOfStruct{i})'];
    end
    % set all the fields on each struct if not already set
    % this might be a bad idea, but the only option to convert to table
    % where all fields are needed
    for i = 1:numel(cellArrayOfStruct)
        for j = 1:numel(fields)
            if (~propAvailable(cellArrayOfStruct{i}, fields{j}))
                cellArrayOfStruct{i}.(fields{j}) = NaN;
            end
        end
    end
    % finally, convert
    m = cell2mat(cellArrayOfStruct);
    t = struct2table(m);
end

