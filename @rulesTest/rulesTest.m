classdef rulesTest < matlab.unittest.TestCase
    %RULESTEST Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        testMarket
    end
    
    methods
        function obj = rulesTest %constructor
             obj.testMarket = marketData('RTS', {'01-Jan-2009' '31-Dec-2013'});                  
        end %constructor       
    end
    
    methods (Test)
        
        function testRule(obj, FileName) 
            disp(FileName)
            ruleUnderTest = positionParent.loadFromFile( FileName );
            ruleUnderTest = ruleUnderTest.findActiveBars(obj.testMarket);
            actSolution = round(ruleUnderTest.Indicator*100)/100;
            expSolution= round(ruleUnderTest.selfTest(ruleUnderTest)*100)/100;
            obj.verifyEqual(actSolution,expSolution);
        end      
        
    end
    
end

