classdef ConfigUtils
    % ConfigUtils: Utility functions for parsing configuration files.
    
    methods (Static)
        function config = parseConfigFile(configFile)
            % Parses a config file (JSON, YAML, or INI) and returns a struct.
            %
            % Example:
            %   config = ConfigUtils.parseConfigFile('config.json');

            [~, ~, ext] = fileparts(configFile);
            
            switch lower(ext)
                case '.json'
                    fid = fopen(configFile, 'r');
                    raw = fread(fid, inf, 'uint8=>char')';
                    fclose(fid);
                    config = jsondecode(raw);
                    
                case '.yaml'
                    % Requires MATLAB YAML parser (e.g., YAMLMatlab library)
                    config = ReadYaml(configFile);
                    
                case '.ini'
                    config = ConfigUtils.parseIniFile(configFile);
                    
                otherwise
                    error('ConfigUtils:UnsupportedFileType', 'Unsupported config file type: %s', ext);
            end
        end

        function config = parseIniFile(iniFile)
            % Parses an INI file into a struct.
            %
            % Example:
            %   config = ConfigUtils.parseIniFile('config.ini');

            config = struct();
            fid = fopen(iniFile, 'r');
            
            while ~feof(fid)
                line = strtrim(fgetl(fid));
                if isempty(line) || line(1) == ';' || line(1) == '#' % Ignore comments
                    continue;
                end
                keyVal = strsplit(line, '=', 2);
                if numel(keyVal) == 2
                    key = strtrim(keyVal{1});
                    value = str2double(strtrim(keyVal{2}));
                    if isnan(value)
                        value = strtrim(keyVal{2});
                    end
                    config.(key) = value;
                end
            end
            fclose(fid);
        end
    end
end
