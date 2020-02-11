function [t] = simplifyTable(t)
%SIMPLIFYTABLE Remove complicated row types from array
%   E.g. cells.
    if (~istable(t))
        error("Expecting table.");
    end

     for var = t.Properties.VariableNames
         type = class(table2array(t(:, var)));
         new_var = strcat(var, '_simplified');
         switch type
             case 'cell'
                 try
                     t(:, new_var) = cellstr(string(table2array(t(:, var))));
                 catch
                     % handle struct
                     t = flattenStruct(t, var);
                     % TODO: use recursion to handle struct fields being
                     % (cells|...) too?
                     % error mainly if 0x... = empty cells
                     non_empty_cells = cellfun(@is_processable, table2cell(t(:, var)));
                     % prepare for being deleted
                     t(:, new_var) = t(:, var);
                     % turn everything else into strings
                     t(non_empty_cells, new_var) = cellstr(string(table2array(t(non_empty_cells, var))));
                     % empty cells: make NaN
                     t(~non_empty_cells, new_var) = {num2cell(nan(1, 1))};
                 end
                 
                 try
                     % also, try to convert to numeric
                     empty_cells = cellfun(@isempty, b);
                     non_empty_vals = t(~empty_cells, new_var);
                     str_values = string(table2array(non_empty_vals));
                     double_vals = str2double(str_values);
                     wrong_double_vals = isnan(double_vals);
                     non_empty_vals(~wrong_double_vals) = double_vals(~wrong_double_vals);
                     t(~empty_cells, new_var) = non_empty_vals;
                 catch
                 end
                 t = removevars(t, var);
             case 'datetime'
                 t(:, new_var) = num2cell(datenum(table2array(t(:, var))));
                 t = removevars(t, var);
             otherwise
                 %fprintf("Type %s deemed ok.\n", type)
         end
     end
end

function [t] = flattenStruct(t, var)
    cells = table2cell(t(:, var));
    struct_idx = cellfun(@isstruct, cells);
    structs = cells(struct_idx);
    if (~isempty(structs))
        for i = 1:numel(structs)
            s = structs{i};
            names = fieldnames(s);
            for n = 1:numel(names)
                try
                    t(i, strcat(var, '_flat_', names{n})) = num2cell(getfield(s, names{n}));
                catch
                	t(i, strcat(var, '_flat_', names{n})) = cellstr(getfield(s, names{n}));
                end
            end
            t(i, var) = cellstr("NaN");
        end
    end
end

function [b] = is_processable(c)
    if (isempty(c) || isstruct(c))
       b = 0;
    elseif (iscell(c))
        b = sum(cellfun(@is_processable, c));
    else
        b = ~sum(isnan(c));
    end
    b = logical(b);
end