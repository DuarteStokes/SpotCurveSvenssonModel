
tic % Measure code performance

folderPath = 'H:\Svensson model\Excel files';
workbook_name = 'Dataset';
workbook_extension = 'xlsm';
worksheetName = 'Sheet1';
rangeName = 'data';
variableType = 'cell_array';

objImportExcel = ImportExcel(folderPath, workbook_name, ...
    workbook_extension, worksheetName, rangeName, variableType);

objImportExcel.import_data()

%--------------------------------------------------------------------------

objBondCreate = BondCreate(objImportExcel.cache.data);
objBondCreate.generate_object_arrays()

toc
