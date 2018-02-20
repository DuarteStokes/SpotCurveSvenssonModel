
classdef(Sealed) ZeroCouponBond < Bond
    
    methods(Access = 'public')
        function self = ZeroCouponBond(ID, lastPrice, maturityDate)
        % Class constructor
        %------------------------------------------------------------------  
            if nargin == 0
                return % Facilitate the preallocation of object arrays
            end
        
            self.construction_private_method(ID, lastPrice, maturityDate)
        end      
        
        function compute_ytm(self)
            self.compute_bondMaturity()
            
            self.cache.ytm = 100 / self.cache.bondMaturity * ...
                log(self.faceValue / self.lastPrice);
        end
    end
    
end
