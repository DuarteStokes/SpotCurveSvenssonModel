
classdef(Sealed) Optimization < handle
% Optimization class definition file
    
    properties(GetAccess = 'public', SetAccess = 'immutable')
        yieldCurveModel
            % Yield curve model (string)
        bestMinimizer
            % Best minimizer (column vector)
        optimizedObjective
            % Optimized objective function value (scalar)
        exitflag
            % Optimization exitflag (scalar)
        output = struct
            % Optimization output
        minimizersMatrix    
            % Minimizers matrix
    end
    
    methods(Access = 'public')
        function self = Optimization(yieldCurveModel, bestMinimizer, ...
            optimizedObjective, exitflag, output, minimizersMatrix)
        % Class constructor
        %------------------------------------------------------------------
            if nargin == 0
                return % Facilitate the preallocation of object arrays
            end
        
            %--------------------------------------------------------------
            
            c1 = strcmp(yieldCurveModel, 'Nelson-Siegel');
            c2 = strcmp(yieldCurveModel, 'Svensson');
            
            if c1 == true || c2 == true
                self.yieldCurveModel = yieldCurveModel;
            else
                message = 'yieldCurveModel input error';
                error(message)
            end
            
            %--------------------------------------------------------------
            
            c1 = isnumeric(bestMinimizer);
            c2 = size(bestMinimizer, 1) == numel(bestMinimizer);
            
            if c1 == true && c2 == true
                self.bestMinimizer = bestMinimizer;
            else
                message = 'bestMinimizer input error';
                error(message)
            end
            
            %--------------------------------------------------------------
             
            c1 = isnumeric(optimizedObjective);
            c2 = numel(optimizedObjective) == 1;
            
            if c1 == true && c2 == true
                self.optimizedObjective = optimizedObjective;
            else
                message = 'optimizedObjective input error';
                error(message)
            end
            
            %--------------------------------------------------------------

            c1 = isnumeric(exitflag);
            c2 = numel(exitflag) == 1;
            c3 = exitflag == fix(exitflag); 
            
            if c1 == true && c2 == true && c3 == true
                self.exitflag = exitflag;
            else
                message = 'exitflag input error';
                error(message)
            end
            
            %--------------------------------------------------------------
            
            if isstruct(output)
                self.output = output;
            else
                message = 'output input error';
                error(message)
            end
            
            %--------------------------------------------------------------
            
            if nargin >= 6
                c1 = isnumeric(minimizersMatrix);
                c2 = size(minimizersMatrix, 1) == numel(bestMinimizer);
            
                if c1 == true && c2 == true
                    self.minimizersMatrix = minimizersMatrix;
                else
                    message = 'minimizersMatrix input error';
                    error(message)
                end
            end
        end
    end
    
end
