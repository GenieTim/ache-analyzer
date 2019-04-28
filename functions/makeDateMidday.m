function [dateT] = makeDateMidday(dateT)
%MAKEDATEMIDDAY Set the time of a datetime to midday
    if (~isdatetime(dateT))
    	warning("Parameter time is required to be MATLABs datetime");
    end
    
    dateT.Hour = 12;
    dateT.Minute = 0;
    dateT.Second = 0;
end

