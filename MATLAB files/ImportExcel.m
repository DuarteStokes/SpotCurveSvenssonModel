
classdef(Sealed) ImportExcel < handle
% Import content from Microsoft Excel
    
    properties(GetAccess = 'public', SetAccess = 'immutable')
        folderPath
            % Folder path
        workbook = struct
            % Structure with 2 fields
            % 1st field: name (access with workbook.name)
            % 2nd field: extension (access with workbook.extension)
        worksheetName
            % Worksheet name
        rangeName
            % Range name
        variableType
            % Chosen MATLAB variable type
    end
    
    properties(GetAccess = 'public', SetAccess = 'private')
        cache = struct
            % Important field: data
    end

    methods(Access = 'public')
        function self = ImportExcel(folderPath, workbook_name, ...
            workbook_extension, worksheetName, rangeName, variableType)
        % Class constructor
        %------------------------------------------------------------------
            if nargin < 6
                message = 'Not enough input arguments';
                error(message) % Generate error
            end
            
            % Cell array preallocation
            cell_array = cell(nargin, 1);
            
            % Fill cells within cell_array
            cell_array{1, 1} = folderPath;
            cell_array{2, 1} = workbook_name;
            cell_array{3, 1} = workbook_extension;
            cell_array{4, 1} = worksheetName;
            cell_array{5, 1} = rangeName;
            cell_array{6, 1} = variableType;
            
            % Make sure that all cells within cell_array contain a string
            for i = 1:numel(cell_array) % For each cell...
                if not(ischar(cell_array{i, 1}))
                    message = 'Wrong data type';
                    error(message)
                end
            end
            
            % Specific workbook_extension test
            c1 = strcmp(workbook_extension, 'xlsx');
            c2 = strcmp(workbook_extension, 'xlsm');
            if c1 == false && c2 == false
                message = 'workbook_extension input error';
                error(message)
            end
            
            % Specific variableType test
            c1 = strcmp(variableType, 'matrix');
            c2 = strcmp(variableType, 'cell_array');
            if c1 == false && c2 == false
                message = 'variableType input error';
                error(message)
            end
            
            % Set properties
            self.folderPath = folderPath;
            self.workbook.name = workbook_name;
            self.workbook.extension = workbook_extension;
            self.worksheetName = worksheetName;
            self.rangeName = rangeName;
            self.variableType = variableType;
        end
        
        function import_data(self)
            % Character array concatenation
            filename = [self.folderPath, '\', self.workbook.name, '.', ...
                self.workbook.extension]; 
            
            % Display filename
            display(['filename: ',filename])
            
            % Import Excel range
            if strcmp(self.variableType, 'matrix')
                self.cache.data = xlsread(filename, ...
                    self.worksheetName, self.rangeName);
            else
                [~, ~, self.cache.data] = xlsread(filename, ...
                    self.worksheetName, self.rangeName);
            end
        end
    end
    
end
