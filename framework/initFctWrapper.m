function initFctWrapper(obj)
try
    obj.init();
catch ME
    lasterr(ME.message);
    warning(ME.getReport);
    rethrow(ME);
end
end

