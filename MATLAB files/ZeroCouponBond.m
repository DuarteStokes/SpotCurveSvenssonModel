
classdef(Sealed) ZeroCouponBond < Bond
    
    methods(Access = 'public')
        function self = ZeroCouponBond(ID, lastPrice, maturityDate)
        % Class constructor
        %------------------------------------------------------------------  
            if nargin == 0
                return % Facilitate the preallocation of object arrays
            end
            
            self.construction_private_method(ID, lastPrice, maturityDate)
            self.compute_bondMaturity()
            self.compute_ytm()
        end
    end
    
    methods(Access = 'private')
        function compute_ytm(self)
            self.cache.ytm = 100 / self.cache.bondMaturity * ...
                log(self.faceValue / self.lastPrice);
        end
    end
    
end
