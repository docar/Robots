classdef marketTest < matlab.unittest.TestCase
    %MARKETTEST Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        testMarket
    end
    
    methods
        function obj = rulesTest %constructor                         
        end %constructor       
    end
    
    methods (Test)
        
        function testMarketLoader(obj, MarketName, TimeInterval) 
            tic
            actSolution = marketData(MarketName, TimeInterval);  
            toc
            tic
            expSolution= marketData2(MarketName, TimeInterval);  
            toc
            obj.verifyEqual(actSolution.DataBase,expSolution.DataBase);
        end      
        
    end
    
end

