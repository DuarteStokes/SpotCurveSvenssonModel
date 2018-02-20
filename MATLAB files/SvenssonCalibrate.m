
classdef(Sealed) SvenssonCalibrate < handle
% Calibrate Svensson's model
   
    properties(GetAccess = 'public', SetAccess = 'immutable')
        objArrayZeroCouponBond
            % (m1 x 1) ZeroCouponBond object array
        objArrayFixedRateBond
            % (m2 x 1) FixedRateBond object array
        numberLocalSolverRuns
            % Number of local solver runs
    end
    
    properties(GetAccess = 'public', SetAccess = 'private')
        cache = struct
            % Cache structure
            % Important field: objArrayOptimization [(2 x 1) object array] 
    end
    
    methods(Access = 'public')
        function self = SvenssonCalibrate(objArrayZeroCouponBond, ...
            objArrayFixedRateBond, numberLocalSolverRuns)
        % Class constructor        
        %------------------------------------------------------------------
            c1 = size(objArrayZeroCouponBond, 1) == ...
                numel(objArrayZeroCouponBond);
            
            c2 = isa(objArrayZeroCouponBond, 'ZeroCouponBond');
            
            if c1 == true && c2 == true
                self.objArrayZeroCouponBond = objArrayZeroCouponBond;
                self.cache.m1 = numel(objArrayZeroCouponBond);
            else
                message = 'objArrayZeroCouponBond input error';
                error(message)
            end
            
            %--------------------------------------------------------------
            
            c1 = size(objArrayFixedRateBond, 1) == ...
                numel(objArrayFixedRateBond);
            
            c2 = isa(objArrayFixedRateBond, 'FixedRateBond');
            
            if c1 == true && c2 == true
                self.objArrayFixedRateBond = objArrayFixedRateBond;
                self.cache.m2 = numel(objArrayFixedRateBond);
            else
                message = 'objArrayFixedRateBond input error';
                error(message)
            end
            
            %--------------------------------------------------------------
            
            c1 = isnumeric(numberLocalSolverRuns);
            c2 = numberLocalSolverRuns >= 1;
            c3 = numberLocalSolverRuns == fix(numberLocalSolverRuns);
            
            if c1 == true && c2 == true && c3 == true
                self.numberLocalSolverRuns = numberLocalSolverRuns;
            else
                message = 'numberLocalSolverRuns input error';
                error(message)
            end
        end
        
        function calibrate_model(self)
            self.define_optimization_starting_vector()
            self.define_optimization_bounds()
            self.define_local_solver_options()
            self.define_optimization_problem()
            self.define_global_optimization_algorithm_options()
            self.solve_optimization_problem()
        end
        
        function generate_plots(self, folder_path, format)
            self.plot_zero_curves(folder_path, format)
            self.plot_residuals(folder_path, format)
        end
    end
    
    methods(Access = 'private')
        function define_optimization_starting_vector(self)
            % Starting vector (column vector) preallocation
            self.cache.x0 = zeros(6, 1);
            
            % Note that:
            % x(1) -> beta1 
            % x(2) -> beta2
            % x(3) -> beta3
            % x(4) -> beta4
            % x(5) -> lambda1
            % x(6) -> lambda2
            
            %--------------------------------------------------------------
            
            % Exploit limiting cases
            
            shortest_maturity_bond_ytm = ...
                self.get_shortest_maturity_bond_ytm();
            
            longest_maturity_bond_ytm = ...
                self.get_longest_maturity_bond_ytm();
            
            %--------------------------------------------------------------
            
            % Populate vector
            
            % Note: lim r(T) as T -> Inf is given by beta1
            self.cache.x0(1) = longest_maturity_bond_ytm; 
            
            % Note: lim r(T) as T -> 0 is given by beta1 + beta2
            self.cache.x0(2) = ...
                shortest_maturity_bond_ytm - self.cache.x0(1); 
            
            self.cache.x0(3) = 0; 
            self.cache.x0(4) = 0; 
            self.cache.x0(5) = 1.4;  
            self.cache.x0(6) = 1;
        end
           
        function define_optimization_bounds(self)
            % Vector of lower bounds
            self.cache.lb = [0; -15; -30; -30; eps(1); 2.5];
            
            % Vector of upper bounds
            self.cache.ub = [15; 30; 30; 30; 2.5; 5.5];
        end
            
        function define_local_solver_options(self)
        % Optimization Toolbox required    
        %------------------------------------------------------------------    
            % Define fmincon options
            self.cache.fminconOptions = optimoptions('fmincon', ...
                'Algorithm', 'sqp', 'Diagnostics', 'off', ...
                'Display', 'off', 'FinDiffType', 'central', ...
                'MaxFunEvals', Inf, 'MaxIter', Inf, ...
                'TolFun', 1e-7, 'TolX', 1e-7, 'UseParallel', false);
        end
        
        function define_optimization_problem(self)
            % Create optimization problem structure
            problem.objective = @(x) compute_objective_function(self, x);
            problem.x0 = self.cache.x0;
            problem.Aineq = [];
            problem.bineq = [];
            problem.Aeq = [];
            problem.beq = [];
            problem.lb = self.cache.lb;
            problem.ub = self.cache.ub;
            problem.nonlcon = [];
            problem.solver = 'fmincon';
            problem.options = self.cache.fminconOptions;
            
            % Store in cache
            self.cache.problem = problem;
        end
        
        function define_global_optimization_algorithm_options(self)
        % Global Optimization Toolbox required
        %------------------------------------------------------------------
            % Construct MultiStart object
            self.cache.objMultiStart = MultiStart('Display', 'off', ...
                'MaxTime', Inf, 'StartPointsToRun', 'bounds', ...
                'TolFun', 1e-7, 'TolX', 1e-7, 'UseParallel', true);
        end
        
        function solve_optimization_problem(self)
        %------------------------------------------------------------------    
            % Preallocation
            self.cache.objArrayOptimization(2, 1) = Optimization();
            
            %--------------------------------------------------------------
            
            % Nelson-Siegel model calibration 
            
            % Redefine optimization lower bounds
            lb = self.cache.lb; % Copy
            lb(4) = 0; % Impose beta4 >= 0  
            lb(6) = 1; % Impose lambda2 >= 1
            
            % Redefine optimization upper bounds
            ub = self.cache.ub; % Copy
            ub(4) = 0; % Impose beta4 <= 0 
            ub(6) = 1; % Impose lambda2 <= 1
            
            % Impose redefined optimization bounds
            self.cache.problem.lb = lb;
            self.cache.problem.ub = ub;
            
            % Run MultiStart
            [bestMinimizer, optimizedObjective, exitflag, output] = ...
                run(self.cache.objMultiStart, self.cache.problem, ...
                self.numberLocalSolverRuns);
            
            % Construct Optimization object
            self.cache.objArrayOptimization(1) = Optimization( ...
                'Nelson-Siegel', bestMinimizer, optimizedObjective, ...
                exitflag, output); 
            
            %--------------------------------------------------------------
            
            % Svensson model calibration
            
            % Redefine starting vector
            self.cache.problem.x0 = bestMinimizer;
            
            % Replace optimization bounds
            self.cache.problem.lb = self.cache.lb;
            self.cache.problem.ub = self.cache.ub;
            
            % Call MultiStart
            [bestMinimizer, optimizedObjective, exitflag, output] = ...
                run(self.cache.objMultiStart, self.cache.problem, ...
                self.numberLocalSolverRuns);
            
            % Construct Optimization object
            self.cache.objArrayOptimization(2) = Optimization( ...
                'Svensson', bestMinimizer, optimizedObjective, ...
                exitflag, output); 
        end
        
        function plot_zero_curves(self, folder_path, format)
            % New figure
            figure 
            
            x_axis_lb = 0.01;
            x_axis_step = x_axis_lb;
            x_axis_ub = max(30, max(self.cache.bondMaturity_vector));
            x_axis = transpose(x_axis_lb : x_axis_step : x_axis_ub);
            
            %--------------------------------------------------------------
            
            % Nelson-Siegel model zero curve plot
            
            self.cache.modelParameters = ...
                self.cache.objArrayOptimization(1).bestMinimizer;
            
            nelson_siegel_y_axis = self.compute_spot_rates(x_axis);
            
            plot(x_axis, nelson_siegel_y_axis, 'r')
            
            %--------------------------------------------------------------
            
            % Svensson model zero curve plot
            
            self.cache.modelParameters = ...
                self.cache.objArrayOptimization(2).bestMinimizer;
            
            svensson_y_axis = self.compute_spot_rates(x_axis);
            
            grid on
            hold on
            plot(x_axis, svensson_y_axis, 'b')
            
            %--------------------------------------------------------------
            
            % Yields to maturity plot
            
            hold on
            plot(self.cache.bondMaturity_vector, self.cache.ytm_vector, ...
                'g*')
            
            %--------------------------------------------------------------
            
            hold on
            plot(x_axis, zeros(size(x_axis)), 'k')
            
            xlim([0 x_axis_ub])
            
            xlabel('Maturity', 'fontsize', 16)
            ylabel('Interest rate (%)', 'fontsize', 16)
            
            % Enhance code readability
            valuationDate = self.objArrayZeroCouponBond(1).valuationDate;
            currency = self.objArrayZeroCouponBond(1).currency;
            creditQuality = self.objArrayZeroCouponBond(1).creditQuality;
            
            title_string = [currency, ' ', creditQuality];
            title_string = [title_string, ' term structure of '];
            title_string = [title_string, 'interest rates ('];
            title_string = [title_string, datestr(valuationDate), ')'];
            title(title_string, 'fontsize', 20)
            
            legend('Nelson-Siegel zero curve', 'Svensson zero curve', ...
                'Yields to maturity', 'Location', 'northwest', ...
                'Orientation', 'vertical', 'fontsize', 16)
            
            %--------------------------------------------------------------
            
            filename = [currency, ' ', creditQuality, ' zero curves ('];
            filename = [filename, datestr(valuationDate), ')'];
            filename = [folder_path, '\', filename, '.', format];
            
            % Save figure
            saveas(gcf, filename)
        end
        
        function plot_residuals(self, folder_path, format)
            % New figure
            figure
            
            % Create x_axis vector
            x_axis = transpose(1 : (self.cache.m1 + self.cache.m2));
            
            ---------------------------------------------------------------
            
            % Nelson-Siegel model residuals plot
            
            % Update cache
            x = self.cache.objArrayOptimization(1).bestMinimizer;
            self.compute_objective_function(x);
            
            % Concatenate
            nelson_siegel_residuals_vector = [ ...
                self.cache.ZeroCouponBond_residuals_vector; 
                self.cache.FixedRateBond_residuals_vector];
            
            plot(x_axis, nelson_siegel_residuals_vector, 'r*')
            
            %--------------------------------------------------------------
            
            % Svensson model residuals plot
            
            % Update cache
            x = self.cache.objArrayOptimization(2).bestMinimizer;
            self.compute_objective_function(x);
            
            % Concatenate
            svensson_residuals_vector = [ ...
                self.cache.ZeroCouponBond_residuals_vector; 
                self.cache.FixedRateBond_residuals_vector];
            
            grid on
            hold on
            plot(x_axis, nelson_siegel_residuals_vector, 'b*')
            
            %--------------------------------------------------------------
            
            hold on
            plot(x_axis, zeros(size(x_axis)), 'k')
            
            ylabel('Residual', 'fontsize', 16)
            
            title('Model calibration residuals', 'fontsize', 20)
            
            legend('Nelson-Siegel residuals', 'Svensson residuals', ...
                'Location', 'northeast', 'Orientation', 'vertical', ...
                'fontsize', 16)
            
            %--------------------------------------------------------------
            
            % Enhance code readability
            valuationDate = self.objArrayZeroCouponBond(1).valuationDate;
            currency = self.objArrayZeroCouponBond(1).currency;
            creditQuality = self.objArrayZeroCouponBond(1).creditQuality;
            
            filename = [currency, ' ', creditQuality, ' model residuals'];
            filename = [filename, ' (', datestr(valuationDate), ')'];
            filename = [folder_path, '\', filename, '.', format];
            
            % Save figure
            saveas(gcf, filename)
        end
    end
    
    methods(Access = 'private')
        function shortest_maturity_bond_ytm = ...
            get_shortest_maturity_bond_ytm(self)
        %------------------------------------------------------------------
            % Enhance code readability
            m = self.cache.m1 + self.cache.m2;
        
            % Preallocation
            self.cache.bondMaturity_vector = zeros(m, 1); 
            self.cache.ytm_vector = zeros(m, 1); 
            
            %--------------------------------------------------------------
            
            % Populate both vectors
            for i = 1:m % For each row...
                if i <= self.cache.m1
                    self.cache.bondMaturity_vector(i) = ...
                        self.objArrayZeroCouponBond(i).cache.bondMaturity;
                    
                    self.cache.ytm_vector(i) = ...
                        self.objArrayZeroCouponBond(i).cache.ytm;
                else                                         
                    self.cache.bondMaturity_vector(i) = ...
                        self.objArrayFixedRateBond(i - self.cache.m1). ...
                        cache.bondMaturity;
                    
                    self.cache.ytm_vector(i) = ...
                        self.objArrayFixedRateBond(i - self.cache.m1). ...
                        cache.ytm;
                end
            end
            
            %--------------------------------------------------------------
            
            % Find shortest maturity bond ytm
            [~, min_index] = min(self.cache.bondMaturity_vector);
            shortest_maturity_bond_ytm = self.cache.ytm_vector(min_index);
        end                              
        
        function longest_maturity_bond_ytm = ...
            get_longest_maturity_bond_ytm(self)
        %------------------------------------------------------------------
            % Find longest maturity bond ytm
            [~, max_index] = max(self.cache.bondMaturity_vector);
            longest_maturity_bond_ytm = self.cache.ytm_vector(max_index); 
        end

        function f = compute_objective_function(self, x)
            % Store in cache
            self.cache.modelParameters = x;
            
            % Preallocation 
            ZeroCouponBond_market_prices = zeros(self.cache.m1, 1);
            ZeroCouponBond_model_prices = zeros(self.cache.m1, 1);
            
            % Preallocation
            FixedRateBond_market_prices = zeros(self.cache.m2, 1);
            FixedRateBond_model_prices = zeros(self.cache.m2, 1);
            
            %--------------------------------------------------------------
            
            % Fill vectors
            
            % Handle zero coupon bonds
            for i = 1:self.cache.m1 % For each zero coupon bond...
                ZeroCouponBond_market_prices(i) = ...
                    self.objArrayZeroCouponBond(i).lastPrice;
                                               
                discount_factors = self.compute_discount_factors( ...
                    'ZeroCouponBond', i);

                ZeroCouponBond_model_prices(i) = self. ...
                    objArrayZeroCouponBond(i).faceValue * discount_factors;
            end
            
            % Handle fixed rate bonds
            for i = 1:self.cache.m2 % For each fixed rate bond...
                FixedRateBond_market_prices(i) = ...
                    self.objArrayFixedRateBond(i).lastPrice;
                
                discount_factors = self.compute_discount_factors( ...
                    'FixedRateBond', i);
                
                FixedRateBond_model_prices(i) = self. ...
                    objArrayFixedRateBond(i).cache.cashflows.values' * ...
                    discount_factors;
            end
            
            
            %--------------------------------------------------------------
            
            % Compute Euclidean distance
            
            self.cache.ZeroCouponBond_residuals_vector = ...
                ZeroCouponBond_market_prices - ...
                ZeroCouponBond_model_prices;
            
            self.cache.FixedRateBond_residuals_vector = ...
                FixedRateBond_market_prices - ...
                FixedRateBond_model_prices;
            
            % Compute inner product
            f = self.cache.ZeroCouponBond_residuals_vector' * ...
                self.cache.ZeroCouponBond_residuals_vector + ...
                self.cache.FixedRateBond_residuals_vector' * ...
                self.cache.FixedRateBond_residuals_vector;
            
            % Take the square root
            % Note that g(y) = sqrt(y) is strictly increasing for all y > 0
            f = sqrt(f);
            
            % Set field to empty
            self.cache.modelParameters = [];
        end
    end
    
    methods(Access = 'private')
        function discount_factors = compute_discount_factors(self, ...
            bond_type, object_array_index)
        %------------------------------------------------------------------    
            cashflows_maturities = self.compute_cashflows_maturities( ...
                bond_type, object_array_index); 
            
            spot_rates = self.compute_spot_rates(cashflows_maturities);
            
            aux_vector = (-1) * (spot_rates / 100) .* cashflows_maturities;
            discount_factors = exp(aux_vector);
        end
    end
    
    methods(Access = 'private')        
        function cashflows_maturities = compute_cashflows_maturities( ...
            self, bond_type, object_array_index)
        %------------------------------------------------------------------
            switch bond_type
                case 'ZeroCouponBond'
                    cashflows_maturities = self. ...
                        objArrayZeroCouponBond(object_array_index). ...
                        cache.bondMaturity;
                case 'FixedRateBond'
                    cashflows_maturities = self. ...
                        objArrayFixedRateBond(object_array_index). ...
                        cache.cashflows.maturities;
                otherwise
                    message = 'bond_type input error';
                    error(message)
            end
        end
   
        function spot_rates = compute_spot_rates(self, ...
            cashflows_maturities)
        %------------------------------------------------------------------
            % Enhance code readability
            beta1 = self.cache.modelParameters(1);
            beta2 = self.cache.modelParameters(2);
            beta3 = self.cache.modelParameters(3);
            beta4 = self.cache.modelParameters(4); 
            lambda1 = self.cache.modelParameters(5); 
            lambda2 = self.cache.modelParameters(6);
            
            %--------------------------------------------------------------
            
            % 1st part
            
            aux_vector0 = exp((-1) * cashflows_maturities / lambda1);
            aux_vector1 = 1 - aux_vector0;
            aux_vector2 = aux_vector1 ./ (cashflows_maturities / lambda1);
            aux_vector3 = aux_vector2 - aux_vector0;
            
            spot_rates = beta1 + beta2 * aux_vector2 + beta3 * aux_vector3;
            
            %--------------------------------------------------------------

            % 2nd part
            
            aux_vector1 = exp((-1) * cashflows_maturities / lambda2);
            aux_vector2 = 1 - aux_vector1;
            aux_vector3 = aux_vector2 ./ (cashflows_maturities / lambda2);
            aux_vector4 = aux_vector3 - aux_vector1;
            
            spot_rates = spot_rates + beta4 * aux_vector4;
        end
    end
    
end
