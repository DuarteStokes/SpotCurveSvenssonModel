
classdef(Sealed) FixedRateBond < Bond
    
    properties(GetAccess = 'public', SetAccess = 'immutable')
        annualCouponRate
            % Annual coupon rate (stated in percentage)
        couponFrequency
            % Coupon frequency
            % couponFrequency = 1 => annual frequency
            % couponFrequency = 2 => semi-annual frequency
            % couponFrequency = 4 => quarterly frequency
            % couponFrequency = 12 => monthly frequency
    end
    
    methods(Access = 'public')
        function self = FixedRateBond(ID, lastPrice, maturityDate, ...
            annualCouponRate, couponFrequency)
        % Class constructor
        %------------------------------------------------------------------
            if nargin == 0
                return % Facilitate the preallocation of object arrays
            end
        
            self.construction_private_method(ID, lastPrice, maturityDate)
        
            %--------------------------------------------------------------
            
            if isnumeric(annualCouponRate) && annualCouponRate > 0 
                self.annualCouponRate = annualCouponRate;
            else
                message = 'annualCouponRate input error';
                error(message)
            end
        
            %--------------------------------------------------------------
        
            % List all possible coupon frequencies
            couponFrequency_list = [1; 2; 4; 12]; 
            
            if max(couponFrequency == couponFrequency_list) == 1
                self.couponFrequency = couponFrequency;
            else
                message = 'couponFrequency input error';
                error(message)
            end
            
            %--------------------------------------------------------------
            
            % Call private method
            self.main_method()
        end
    end    
       
    methods(Access = 'private')
        function main_method(self)
            self.compute_bondMaturity()
            self.compute_cashflows_maturities()
            self.compute_cashflows_values()
            self.compute_ytm()
        end
    end
    
    methods(Access = 'private') 
        function compute_cashflows_maturities(self)
            % Compute time interval (measured in years) between payments
            time_interval_between_payments = 1 / self.couponFrequency;
            
            % Initialization
            cashflows_counter = 1;
            modifiable_cashflow_maturity = self.cache.bondMaturity;
            
            % Boolean decision variable
            increase_cashflows_counter = ...
                modifiable_cashflow_maturity > ...
                time_interval_between_payments;
            
            while increase_cashflows_counter == 1
                % Update cashflows_counter
                cashflows_counter = cashflows_counter + 1;
               
                % Update modifiable_cashflow_maturity
                modifiable_cashflow_maturity = ...
                    modifiable_cashflow_maturity - ...
                    time_interval_between_payments;
                
                % Recompute boolean decision variable
                increase_cashflows_counter = ...
                    modifiable_cashflow_maturity > ...
                    time_interval_between_payments;
            end
            
            % Generate cashflows' maturities (column) vector
            self.cache.cashflows.maturities = ...
                zeros(cashflows_counter, 1);
            
            %--------------------------------------------------------------
            
            % Populate cashflows' maturities vector
            
            self.cache.cashflows.maturities(1) = ...
                modifiable_cashflow_maturity;
            
            if cashflows_counter >= 2
                for i = 2:cashflows_counter
                    self.cache.cashflows.maturities(i) = ...
                        self.cache.cashflows.maturities(i-1) + ...
                        time_interval_between_payments;
                end
            end
        end
                 
        function compute_cashflows_values(self) 
            % Compute coupon payment
            coupon_payment = self.faceValue * ...
                (self.annualCouponRate / 100) / self.couponFrequency;
              
            % Generate cashflows' values vector
            self.cache.cashflows.values = repmat(coupon_payment, ...
                size(self.cache.cashflows.maturities));
            
            % Add face value to last payment
            self.cache.cashflows.values(end) = ...
                self.cache.cashflows.values(end) + self.faceValue;
        end
                 
        function compute_ytm(self)
            % Objective function handle
            ytm_objective_function_handle = ...
                @(ytm) ytm_objective_function(self, ytm);
                       
            % Define starting value 
            self.cache.ytm.x0 = 0;
            
            % Call root finder
            [self.cache.ytm.value, ~, self.cache.ytm.exitflag, ...
                self.cache.ytm.output] = ...
                fzero(ytm_objective_function_handle, self.cache.ytm.x0);
        end
    end
    
    methods(Access = 'private')
        function f = ytm_objective_function(self, ytm)
            % Compute discount factors
            discount_factors = exp( ...
                (-1) * (ytm / 100) * ...
                self.cache.cashflows.maturities);
            
            % Use dot product
            f = self.lastPrice - ...
                self.cache.cashflows.values' * discount_factors; 
        end
    end
    
end
