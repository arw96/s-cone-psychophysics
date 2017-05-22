%TODO: to make this generalizable to the Stocman '93 experiment, take the
%following steps:
%       - require that the stimulusParameters have an peak and a mean
%       intensity for all 3 monitor channels
%       - allow for the specification of frequencies of modulation for all
%       3 monitor channels
%       - the stimulusComponents lookup needs to return relative phases for
%       all 3 of the stimuli (maybe still just the advance for blue?)

classdef Oscillator < SConePsychophysics.Cyclers.Cycler
    % this cycler requires stimulus components as follows:
    % stimulus components will be a matrix that will define
    % the stimulus to show - each of them will be scaled by a sinusoid for
    % each frame generation
    
    % require stimulus parameters:
    %       - step size: in units of seconds - defines the incremental
    %       steps used to advance the s cone signal ahead of the others
    %       - frequency - this will be the frequency of the oscillating
    %       stimulus
    
    properties
        factorsInSine
        shapeRectangles
        modulationAmplitudeRGB
    end
    
    properties (Dependent)
        currColor
        currPhaseOffsets
    end
    
    methods
%         function obj = Oscillator(hardwareParameters, stimulusParameters, stimulusComponents)
%             obj = obj@SConePsychophysics.Cyclers.Cycler(hardwareParameters, stimulusParameters, stimulusComponents);
%             
%             obj.ComputeShapeRectangles();
%             obj.factorInSine = 2 * pi * obj.stimulusParameters.frequency;
%             obj.modulationAmplitude = obj.stimulusParameters.peakIntensity - obj.stimulusParameters.backgroundIntensity;
%         end
 
% NEW VERSION
        function obj = Oscillator(hardwareParameters, stimulusParameters, stimulusComponents)
           obj = obj@SConePsychophysics.Cyclers.Cycler(hardwareParameters, stimulusParameters, stimulusComponents);
           
           obj.ComputeShapeRectangles();
           obj.factorsInSine = 2 * pi * obj.stimulusParameters.frequenciesRGB;
           obj.modulationAmplitudeRGB = ...
               obj.stimulusParameters.peakIntensityRGB - obj.stimulusParameters.backgroundIntensityRGB;
        end
        
        function ComputeShapeRectangles(obj)
            hwParams = obj.hardwareParameters;

            stimulusRectangle = obj.DetermineStimulusRectangle();
            
            if obj.hardwareParameters.renderInQuadrants
                width = hwParams.width;
                height = hwParams.height;
                
                baseRectangle = CenterRectOnPoint(obj.DetermineStimulusRectangle(), width / 4, height / 4);
                obj.shapeRectangles = cellfun(@(x) baseRectangle + x, ...
                    {[0 0 0 0], ...
                    [(width / 2) 0 (width / 2) 0], ...
                    [0 (height / 2) 0 (height / 2)], ...
                    [(width / 2) (height / 2) (width / 2) (height / 2)]}, ...
                    'UniformOutput', false);
            else
                screenRectangle = [0 0 hwParams.frameWidth hwParams.frameHeight];
                obj.shapeRectangles = CenterRect(stimulusRectangle, screenRectangle);
            end
        end
        
        function DrawTextureInQuadrants(obj, frameTime)
            frameTimes = obj.CalculateQuadrantFrameTimes(frameTime);
            shapeColors = obj.CalculateShapeColors(frameTimes);
            for i = 1:4
                obj.DrawShape(obj.shapeRectangles{i}, shapeColors{i})
            end
        end
        
        function DrawTextureEntireScreen(obj, frameTime)
            obj.DrawShape(obj.shapeRectangles, obj.CalculateShapeColor(frameTime));
        end
        
        function DrawShape(obj, rectangle, shapeColor)
            Screen('FillOval', obj.hardwareParameters.window, shapeColor, rectangle);
        end
        
        function shapeColors = CalculateShapeColors(obj, frameTimes)
            shapeColors = arrayfun(@(x) obj.CalculateShapeColor(x), frameTimes, 'UniformOutput', false);
        end
        
        function shapeColor = CalculateShapeColor(obj, frameTime)
           shapeColor = obj.stimulusParameters.backgroundIntensityRGB + obj.modulationAmplitudeRGB .* ...
               sin(obj.factorsInSine * frameTime + obj.currPhaseOffsets);
        end
        
        function results = CompileResults(obj)
            results = SConePsychophysics.Utils.Results();
            offsetInRadians = obj.currOffset * obj.stimulusParameters.offsetStepSize;
            offsetInSeconds = (offsetInRadians/ (2 * pi)) / obj.stimulusParameters.frequencyB;
            results.Add('s cone offset in radians', offsetInRadians);
            results.Add('blue channel frequency', obj.stimulusParameters.frequencyB);
            results.Add('offset in seconds', offsetInSeconds);
            results.Add('offset in milliseconds',1000 * offsetInSeconds);
        end
        
        function value = get.currPhaseOffsets(obj)
            value = [0 0 obj.stimulusComponents(obj.currOffset)];
        end
    end
end