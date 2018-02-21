
% This script runs the whole model

tic % Measure code performance

%--------------------------------------------------------------------------

folderPath = 'E:\Svensson model\Excel files';
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
objArrayZeroCouponBond = objBondCreate.cache.objArrayZeroCouponBond;
objArrayFixedRateBond = objBondCreate.cache.objArrayFixedRateBond;

%--------------------------------------------------------------------------

numberLocalSolverRuns = 20000;

objSvenssonCalibrate = SvenssonCalibrate(objArrayZeroCouponBond, ...
    objArrayFixedRateBond, numberLocalSolverRuns);

objSvenssonCalibrate.calibrate_model

folder_path = 'E:\Svensson model\MATLAB files';
format = 'fig';
objSvenssonCalibrate.generate_plots(folder_path, format);

%--------------------------------------------------------------------------

toc
