
classdef(Abstract) Bond < handle
    
    properties(Constant)
        settlementDate = datenum('2/Feb/2017')
            % Settlement date (MATLAB serial date)
        valuationDate = datenum('1/Feb/2017')
            % Valuation date (MATLAB serial date)
        dayCountConvention = '30/360 European'
            % Day count convention
            % Choose either 'actual/360' or '30/360 European'
        faceValue = 100
            % Face value
        currency = 'EUR'
            % Currency
        creditQuality = 'risk-free'
            % Credit quality
    end
    
    properties(GetAccess = 'public', SetAccess = 'private')
        ID
            % Bond ID
        lastPrice
            % Last price
        maturityDate
            % Maturity date (MATLAB serial date)
    end
    
    properties(GetAccess = 'public', SetAccess = 'public')
        cache = struct
            % Cache structure
            % Important field: ytm 
            % ytm stands for yield to maturity
            % ytm is measured with continuous compounding
            % ytm is stated in percentage
    end
    
    methods(Access = 'private')
        function construction_private_method(self, ID, lastPrice, ...
            maturityDate) 
        %------------------------------------------------------------------
            if ischar(ID)
                self.ID = ID;
            else
                message = 'ID input error';
                error(message)
            end
        
            %--------------------------------------------------------------
        
            if isnumeric(lastPrice) && lastPrice > 0
                self.lastPrice = lastPrice;
            else
                message = 'lastPrice input error';
                error(message)
            end
           
            %--------------------------------------------------------------
            
            c1 = isnumeric(maturityDate);
            c2 = maturityDate > 0;
            c3 = maturityDate == fix(maturityDate);
            
            if c1 == true && c2 == true && c3 == true
                self.maturityDate = maturityDate;
            else
                message = 'maturityDate input error';
                error(message)
            end
        end
        
        function compute_bondMaturity(self)
        % Financial Toolbox required
        %------------------------------------------------------------------
            switch self.dayCountConvention
                case 'actual/360'  
                    self.cache.bondMaturity = ...
                        daysdif(self.valuationDate, self.maturityDate, 2); 
                case '30/360 European'
                    self.cache.bondMaturity = ...
                        daysdif(self.valuationDate, self.maturityDate, 6);
            end
            
            self.cache.bondMaturity = self.cache.bondMaturity / 360;
        end
    end
    
end
