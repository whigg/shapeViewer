classdef SaveScene < sv.gui.ShapeViewerAction
%OPENSCENEACTION  save the scene contained in the current doc
%
%   Class OpenSceneAction
%
%   Example
%   OpenSceneAction
%
%   See also
%

% ------
% Author: David Legland
% e-mail: david.legland@inra.fr
% Created: 2018-09-21,    using Matlab 8.6.0.267246 (R2015b)
% Copyright 2018 INRA - BIA-BIBS.


%% Properties
properties
end % end properties


%% Constructor
methods
    function this = SaveScene(varargin)
        % Constructor for OpenSceneAction class

        % calls the parent constructor
        this = this@sv.gui.ShapeViewerAction('saveScene');
    end

end % end constructors


%% Methods
methods
    function run(this, viewer) %#ok<INUSL>
        disp('save current scene');
        
        [fileName, pathName] = uiputfile( ...
            {
            '*.scene',                  'Scene files (*.scene)'; ...
            '*.*',                      'All Files (*.*)'}, ...
            'Choose scene file:', ...
            viewer.gui.lastSavePath);
        
        if isequal(fileName,0) || isequal(pathName,0)
            return;
        end

        % save load path
        viewer.gui.lastSavePath = pathName;
        
        % read the scene frmthe file
        write(viewer.doc.scene, fullfile(pathName, fileName));
        
    end
end % end methods

end % end classdef

