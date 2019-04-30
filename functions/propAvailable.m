function availability = propAvailable(object, property)
%PROPAVAILABLE Summary of this function goes here
%   Detailed explanation goes here
    if (isstruct(object))
        availability = isfield(object, property);
    elseif (istable(object))
        availability = ismember(property, object.Properties.VariableNames);
    elseif (isobject(object))
        availability = isprop(object, property);
    else
        warning('Cannot determine availability of property "%s" on object of class "%s".', property, class(object));
        try 
            test = object.(property);
            availability = 1;
        catch
            availability = 0;
        end
    end
end

