function [exectime,functionhandle] = taskWrapper(seg,functionhandle)
%Wrapper for tasks
%taskWrapper(seg,functionhandle)
%seg...segment
%functionhandle...handle to code method
try
    [exectime, obj] = functionhandle(seg);
catch ME
    lasterr(ME.message);
    warning(ME.getReport);
    rethrow(ME);
end
end



