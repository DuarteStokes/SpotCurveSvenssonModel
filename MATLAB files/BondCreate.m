
classdef(Sealed) BondCreate < handle

    properties(GetAccess = 'public', SetAccess = 'immutable')
        rangeHeaders
            % (1 x n) cell array of headers
    end
    
    properties(GetAccess = 'public', SetAccess = 'private')
        dataRange
            % ((1 + m) x n) cell array 
    end
    
    properties(GetAccess = 'public', SetAccess = 'private')
        cache = struct
            % Cache structure
            % Important field: objArrayZeroCouponBond
            % Important field: objArrayFixedRateBond
    end
    
    methods(Access = 'public')
        function self = BondCreate(dataRange)
        % Class constructor
        %------------------------------------------------------------------
            % Hard code rangeHeaders property 
            self.rangeHeaders = [{'Bond ID'}, {'Last price'}, ...
                {'Maturity date'}, {'Annual coupon rate (%)'}, ...
                {'Coupon frequency'}];
            
            % Store in cache
            self.cache.n = numel(self.rangeHeaders);
            
            % dataRange dimensions test
            c1 = size(dataRange, 1) > 1; 
            c2 = size(dataRange, 2) == self.cache.n;
            if not(c1 == true && c2 == true)
                message = 'dataRange dimensions test failed';
                error(message)
            else
                self.cache.m = size(dataRange, 1) - 1;
            end
            
            % Compatibility test
            for j = self.cache.n 
                if strcmp(self.rangeHeaders{j}, dataRange{1, j}) == false
                    message = 'Compatibility test failed';
                    error(message)
                end
            end
            
            % NaN test
            for i = 1:self.cache.m
                row_index = 1 + i;
                c1 = strcmp(dataRange{row_index, end - 1}, 'NaN'); 
                c2 = strcmp(dataRange{row_index, end}, 'NaN');
                
                if c1 + c2 == 1
                    message = 'NaN test failed';
                    error(message)
                end
            end
            
            % Set dataRange property
            self.dataRange = dataRange; 
        end
        
        function generate_object_arrays(self)
            % Handle dates
            self.handle_dates()
            
            % How many zero coupon bonds?
            NaN_counter = 0; % Initialize counter
            for i = 1:self.cache.m
                row_index = 1 + i;
                if strcmp(self.dataRange{row_index, end - 1}, 'NaN')
                    % Increase counter
                    NaN_counter = NaN_counter + 1;
                end
            end
            ZeroCouponBond_count = NaN_counter;
            FixedRateBond_count = self.cache.m - ZeroCouponBond_count;
            
            % ZeroCouponBond object array preallocation
            objArrayZeroCouponBond(ZeroCouponBond_count, 1) = ...
                ZeroCouponBond();
            
            % FixedRateBond object array preallocation
            objArrayFixedRateBond(FixedRateBond_count, 1) = ...
                FixedRateBond();
            
            % Store in cache
            self.cache.objArrayZeroCouponBond = objArrayZeroCouponBond;
            self.cache.objArrayFixedRateBond = objArrayFixedRateBond;
                       
            % Fill object arrays
            self.fill_object_arrays()
        end
    end
    
    methods(Access = 'private')
        function handle_dates(self)
            for i = 1:self.cache.m
                row_index = 1 + i;
                
                % Check 1st character
                if strcmp(self.dataRange{row_index, 3}(1), '"') == true
                    self.dataRange{row_index, 3} = ...
                        self.dataRange{row_index, 3}(2:end);
                end
                
                % Check last character
                if strcmp(self.dataRange{row_index, 3}(end), '"') == true
                    self.dataRange{row_index, 3} = ...
                        self.dataRange{row_index, 3}(1:end-1);
                end
                
                % Reorganize
                month = self.dataRange{row_index, 3}(1:2);
                day = self.dataRange{row_index, 3}(4:5);
                year = self.dataRange{row_index, 3}(end-3:end);
                
                % Convert from string to double
                month = str2double(month);
                day = str2double(day);
                year = str2double(year);
                
                % Create MATLAB date
                date = datetime(year, month, day);
                
                % Convert to MATLAB serial date
                serial_date = datenum(date);
                
                % Rewrite
                self.dataRange{row_index, 3} = serial_date;
            end
        end
                 
        function fill_object_arrays(self)
            % Indices initialization
            k = 0; % ZeroCouponBond index
            s = 0; % FixedRateBond index
            
            for i = 1:self.cache.m
                row_index = 1 + i;
                
                ID = self.dataRange{row_index, 1};
                lastPrice = self.dataRange{row_index, 2}; 
                maturityDate = self.dataRange{row_index, 3};
                
                if strcmp(self.dataRange{row_index, end - 1}, 'NaN')
                    k = k + 1; % Increase index
                    
                    % Construct ZeroCouponBond object
                    self.cache.objArrayZeroCouponBond(k) = ...
                        ZeroCouponBond(ID, lastPrice, maturityDate);
                else
                    s = s + 1; % Increase index
                    
                    annualCouponRate = self.dataRange{row_index, end - 1};
                    couponFrequency = self.dataRange{row_index, end};
                    
                    % Construct FixedRateBond object
                    self.cache.objArrayFixedRateBond(s) = ...
                        FixedRateBond(ID, lastPrice, maturityDate, ...
                        annualCouponRate, couponFrequency);
                end
            end
        end
    end
    
end
