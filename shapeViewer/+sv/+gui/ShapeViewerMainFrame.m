classdef ShapeViewerMainFrame < handle
%SHAPEVIEWERMAINFRAME  One-line description here, please.
%
%   Class ShapeViewerMainFrame
%
%   Example
%   ShapeViewerMainFrame
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
    % reference to the main GUI instance
    gui;
   
    % list of handles to the various gui items
    handles;
    
    % the document containing the scene
    doc;
    
    % the set of mouse listeners.
    mouseListeners = [];
    
    % the currently selected tool
    currentTool = [];
    
    % the set of selected shapes, stored as a cell array
    selectedShapes = [];

end % end properties


%% Constructor
methods
    function this = ShapeViewerMainFrame(gui, doc)
        this.gui = gui;
        this.doc = doc;
        
        % create default figure
        fig = figure(...
            'MenuBar', 'none', ...
            'NumberTitle', 'off', ...
            'NextPlot', 'new', ...
            'Name', 'Shape Viewer');
        
        % create main figure menu
        setupMenu(fig);
        setupLayout(fig);
        
        this.handles.figure = fig;
        
        updateDisplay(this);
        updateTitle(this);
        
        % setup listeners associated to the figure
        set(fig, ...
            'CloseRequestFcn', @this.close, ...
            'ResizeFcn', @this.onFigureResized);
        
        % setup mouse listeners associated to the figure
        set(fig, 'WindowButtonDownFcn',     @this.processMouseButtonPressed);
        set(fig, 'WindowButtonUpFcn',       @this.processMouseButtonReleased);
        set(fig, 'WindowButtonMotionFcn',   @this.processMouseMoved);

        % setup mouse listener for display of mouse coordinates
        tool = sv.tools.ShowCursorPositionTool(this, 'showMousePosition');
        addMouseListener(this, tool);
        
        tool = sv.tools.SelectionTool(this, 'selection');
        addMouseListener(this, tool);
        this.currentTool = tool;
        
        
        set(fig, 'UserData', this);
        
        function setupMenu(hf)
            
            import sv.actions.*;
            import sv.actions.io.*;
            import sv.actions.edit.*;
            import sv.actions.view.*;
            import sv.tools.*;
            
            % File Menu Definition 
            
            fileMenu = uimenu(hf, 'Label', '&Files');
            
            addMenuItem(fileMenu, CreateNewDocAction(), '&New Document');
           
            action = OpenSceneAction('openScene');
            addMenuItem(fileMenu, action, 'Open Scene...', true);
            action = ImportGeometryFile('importGeometryFile');
            addMenuItem(fileMenu, action, 'Import Geometry', true);
            action = OpenPointsInTableAction('openPointSetInTable');
            addMenuItem(fileMenu, action, 'Import Point &Set');
            action = OpenPolygonInTableAction('openPolygonInTable');
            addMenuItem(fileMenu, action, 'Import Polygon');
            action = OpenPolygonSetInTableAction('openPolygonSetInTable');
            addMenuItem(fileMenu, action, 'Import Polygon Set');
            
            addMenuItem(fileMenu, SaveScene(), 'Save As...', true);

            action = CloseCurrentDocAction('closeDoc');
            addMenuItem(fileMenu, action, '&Close', true);

            
            % Edit Menu Definition 
            
            editMenu = uimenu(hf, 'Label', '&Edit');
            addMenuItem(editMenu, SelectAllShapes(this),      'Select &All');
            addMenuItem(editMenu, DeleteSelectedShapes(), '&Clear Selection');
            addMenuItem(editMenu, PrintSceneInfo(), 'Scene Info', true);
%             addMenuItem(editMenu, SetSelectedShapeStyleAction(this),  'Set Display Style...', true);
            addMenuItem(editMenu, RenameSelectedShape(this),  '&Rename', true);

            viewMenu = uimenu(hf, 'Label', '&View');
            addMenuItem(viewMenu, SetAxisBounds(), 'Set Axis Bounds...');
            addMenuItem(viewMenu, ToggleBackgroundImageDisplay(), 'Toggle Background Image Display', true);
            addMenuItem(viewMenu, ZoomInAction(), 'Zoom &In', true);
            addMenuItem(viewMenu, ZoomOutAction(), 'Zoom &Out');
            
%              % Document Menu Definition 
%             
%             docMenu = uimenu(hf, 'Label', '&Document');
%             addMenuItem(docMenu, AddNewDemoShapeAction(this), 'Add Demo Shape');
%             addMenuItem(docMenu, AddPaperHenShapeAction(this), 'Add Paper Hen Shape');
%             addMenuItem(docMenu, AddRandomPointsAction(this), 'Add Random Points');
%             addMenuItem(docMenu, DisplaySelectionInfoAction(this), 'Display &Info', true);
%             addMenuItem(docMenu, SetDocumentViewBoxAction(this), 'Set &View Box...', true);
%             addMenuItem(docMenu, ToggleDocumentShowAxisLinesAction(this), 'Toggle &Axis Lines');
%             addMenuItem(docMenu, ChangeUserUnitAction(this), 'Change &Unit...');
%             addMenuItem(docMenu, RenameCurrentDocAction(this), '&Rename...');
%             
            
           % Process Menu Definition 
            
            processMenu = uimenu(hf, 'Label', '&Process');

%             % geometric transform of shapes
%             addMenuItem(processMenu, FlipShapeHorizAction(this), '&Horizontal Flip');
%             addMenuItem(processMenu, FlipShapeVertAction(this), '&Vertical Flip');
%             addMenuItem(processMenu, RecenterShapeAction(this), 'Recenter');
%             addMenuItem(processMenu, TranslateShapeAction(this), '&Translate...');
%             addMenuItem(processMenu, ScaleShapeAction(this), '&Scale...');
%             addMenuItem(processMenu, RotateShapeAction(this), '&Rotate...');
% 
%             % computation of derived shapes
%             addMenuItem(processMenu, AddShapeBoundingBoxAction(this), '&Bounding Box', true);
%             addMenuItem(processMenu, AddShapeOrientedBoxAction(this), '&Oriented Box');
%             addMenuItem(processMenu, AddShapeConvexHullAction(this), '&Convex Hull');
%             addMenuItem(processMenu, AddShapeInertiaEllipseAction(this), 'Inertia &Ellipse');
%             
%             % operations on polygons
%             addMenuItem(processMenu, SimplifyPolygonAction(this), ...
%                 'Simplify Polygon/Polyline', true);
%             
%             
            % Tools Menu Definition 
            
            toolsMenu = uimenu(hf, 'Label', '&Tools');
            addMenuItem(toolsMenu, ...
                SelectToolAction(CreateMultiPointTool(this)), ...
                'Create &MultiPoint');
            addMenuItem(toolsMenu, ...
                SelectToolAction(CreatePolygonTool(this)), ...
                'Create &Polygon');
            addMenuItem(toolsMenu, ...
                SelectToolAction(SelectionTool(this)), ...
                'Selection', true);
            
        end % end of setupMenu function

        function item = addMenuItem(menu, action, label, varargin)
            
            % creates new item
            item = uimenu(menu, 'Label', label, ...
                'Callback', @(src, evt) action.run(this));
            
            if ~isActivable(action, this)
                set(item, 'Enable', false);
            end
            
            % eventually add separator above item
            if ~isempty(varargin)
                var = varargin{1};
                if islogical(var)
                    set(item, 'Separator', 'On');
                end
            end
        end
        
        function setupLayout(hf)
            
            % compute background color of most widgets
            bgColor = get(0, 'defaultUicontrolBackgroundColor');
            if ispc
                bgColor = 'White';
            end
            set(hf, 'defaultUicontrolBackgroundColor', bgColor);
            
            % vertical layout for putting status bar on bottom
            mainPanel = uix.VBox('Parent', hf, ...
                'Units', 'normalized', ...
                'Position', [0 0 1 1]);
            
            % horizontal panel: main view nmiddle, options left and right
            horzPanel = uix.HBoxFlex('Parent', mainPanel);
            
            % panel for doc info
            docInfoPanel = uix.VBoxFlex('Parent', horzPanel);

            % create a default uittree
            treePanel = uipanel(...
                'Parent', docInfoPanel, ...
                'Position', [0 0 1 1], ...
                'BorderType', 'none', ...
                'BorderWidth', 0);
            
            this.handles.shapeList = uicontrol(...
                'Style', 'listbox', ...
                'Parent', treePanel, ...
                'String', {'Circle', 'Poly1', 'Poly2', 'Ellipse'}, ...
                'Min', 1, 'Max', 4, ...
                'Units', 'normalized', ...
                'Position', [0 0 1 1], ...
                'Callback', @this.onShapeListModified);

%             displayOptionsPanel = uipanel(...
%                 'parent', docInfoPanel, ...
%                 'Position', [0 0 1 1], ...
%                 'BorderType', 'none', ...
%                 'BorderWidth', 0);
            displayOptionsPanel = uitable(...
                'parent', docInfoPanel, ...
                'Position', [0 0 1 1] );
            
                        
            docInfoPanel.Heights = [-1 -1];
            
            this.handles.docInfoPanel = docInfoPanel;
            this.handles.displayOptionsPanel = displayOptionsPanel;
            


            % panel for image display
            displayPanel = uix.VBox('Parent', horzPanel);
            
            ax = axes('parent', displayPanel, ...
                'units', 'normalized', ...
                'dataAspectRatio', [1 1 1], ...
                'position', [0 0 1 1], ...
            	'XTick', [], ...
            	'YTick', [], ...
            	'Box', 'off');
            
            set(ax, 'XLim', doc.scene.xAxis.limits);
            set(ax, 'YLim', doc.scene.yAxis.limits);
            
            % keep widgets handles
            this.handles.mainAxis = ax;
            
            horzPanel.Widths = [180 -1];
            
            % info panel for cursor position and value
            this.handles.statusBar = uicontrol(...
                'Parent', mainPanel, ...
                'Style', 'text', ...
                'String', ' x=    y=     I=', ...
                'HorizontalAlignment', 'left');
            
            % set up relative sizes of layouts
            mainPanel.Heights = [-1 20];
        end
      
    end
    
end


%% Management of selected shapes
methods
    function clearSelection(this)
        % remove all shapes in the selectedShapes field
        this.selectedShapes = [];
    end
    
    function addToSelection(this, shape)
        this.selectedShapes = [this.selectedShapes shape];
    end
    
    function removeFromSelection(this, shape)
        ind = find(shape == this.selectedShapes);
        if isempty(ind)
            warning('ShapeViewer:MainFrame:Selection', ...
                'could not find a shape in selection list');
            return;
        end
        this.selectedShapes(ind(1)) = [];
    end
    
    function onSelectionUpdated(this)
        updateShapeSelectionDisplay(this);
        updateShapeList(this);
    end
end


%% General methods

methods
    
    function updateDisplay(this)
        % refresh document display: clear axis, draw each shape, udpate axis
        
%         disp('update Display');
        
        ax = this.handles.mainAxis;
        if isempty(this.doc)
            set(ax, 'Visible', 'off');
        end
        
        % clear axis
        cla(ax);
        hold on;

        % start by background image
        if ~isempty(this.doc.scene.backgroundImage) && this.doc.displayBackgroundImage
            show(this.doc.scene.backgroundImage);
        end

        % initialize line handles for axis lines
        if this.doc.scene.axisLinesVisible
            hl1 = plot([0 1], [0 0], 'k-');
            hl2 = plot([0 0], [0 1], 'k-');
        end
        

        % draw each shape in the document
        tool = this.currentTool;
        shapes = this.doc.scene.shapes;
        for i = 1:length(shapes)
            shape = shapes(i);
            hs = draw(shape);
            if ~isempty(tool)
                set(hs, 'buttonDownFcn', @tool.onMouseClicked);
                set(hs, 'UserData', shape);
            end            
            if any(shape == this.selectedShapes)
                set(hs, 'Selected', 'on');
            end
        end
        
        % set axis bounds from view box
        scene = this.doc.scene;
        set(ax, 'XLim', scene.xAxis.limits);
        set(ax, 'YLim', scene.yAxis.limits);
            
        % draw lines for X and Y axes, based on current axis bounds
        if this.doc.scene.axisLinesVisible
%             viewBox = this.doc.viewBox;
%             if isempty(viewBox)
%                 viewBox = [get(ax, 'xlim') get(ax, 'ylim')];
%             end
            set(hl1, 'XData', scene.xAxis.limits, 'Ydata', [0 0]);
            set(hl2, 'Xdata', [0 0], 'YData', scene.yAxis.limits);
        end

        updateShapeList(this);
        
%         disp('end of update Display');
    end
    
    function updateShapeSelectionDisplay(this)
        % update the selected state of each shape
        
        % extract the list of handles in current axis
        ax = this.handles.mainAxis;
        children = get(ax, 'Children');
        
        % iterate over children
        for i = 1:length(children)
            % Extract shape referenced by current handle, if any
            shape = get(children(i), 'UserData');
            if isempty(shape) || ~isa(shape, 'Shape')
                continue;
            end
            
            % update selection state of current shape
            if any(shape == this.selectedShapes)
                set(children(i), 'Selected', 'on');
            else
                set(children(i), 'Selected', 'off');
            end
        end
        
    end
    
    function updateTitle(this)
        % set up title of the figure, containing name of doc
        title = sprintf('%s - ShapeViewer', this.doc.name);
        set(this.handles.figure, 'Name', title);
    end
    
    
    function updateShapeList(this)
        % Refresh the shape tree when a shape is added or removed

        disp('update shape list');
        
        scene = this.doc.scene;
        nShapes = length(scene.shapes);
        shapeNames = cell(nShapes, 1);
        inds = [];
        for i = 1:nShapes
            shape = scene.shapes(i);
            
            % create name for current shape
            name = shape.name;
            if isempty(shape.name)
                name = ['(' class(shape.geometry) ')'];
            end
            shapeNames{i} = name;
            
            % create the set of selected indices
            if any(shape == this.selectedShapes)
                inds = [inds i]; %#ok<AGROW>
            end
        end

        % avoid empty indices, causing problems to gui...
        if nShapes > 0 && isempty(inds)
            inds = 1;
        end
        
        set(this.handles.shapeList, ...
            'String', shapeNames, ...
            'Max', nShapes, ...
            'Value', inds);
    end
end


%% Mouse listeners management
methods
    function addMouseListener(this, listener)
        % Add a mouse listener to this viewer
        this.mouseListeners = [this.mouseListeners {listener}];
    end
    
    function removeMouseListener(this, listener)
        % Remove a mouse listener from this viewer
        
        % find which listeners are the same as the given one
        inds = false(size(this.mouseListeners));
        for i = 1:numel(this.mouseListeners)
            if this.mouseListeners{i} == listener
                inds(i) = true;
            end
        end
        
        % remove first existing listener
        inds = find(inds);
        if ~isempty(inds)
            this.mouseListeners(inds(1)) = [];
        end
    end
    
    function processMouseButtonPressed(this, hObject, eventdata)
        % propagates mouse event to all listeners
        for i = 1:length(this.mouseListeners)
            onMouseButtonPressed(this.mouseListeners{i}, hObject, eventdata);
        end
    end
    
    function processMouseButtonReleased(this, hObject, eventdata)
        % propagates mouse event to all listeners
        for i = 1:length(this.mouseListeners)
            onMouseButtonReleased(this.mouseListeners{i}, hObject, eventdata);
        end
    end
    
    function processMouseMoved(this, hObject, eventdata)
        % propagates mouse event to all listeners
        for i = 1:length(this.mouseListeners)
            onMouseMoved(this.mouseListeners{i}, hObject, eventdata);
        end
    end
end


%% Widget callbacks

methods
    function onShapeListModified(this, varargin)
        
%         disp('shape list updated');
        
        inds = get(this.handles.shapeList, 'Value');
        if isempty(inds)
            return;
        end
        
        this.selectedShapes = this.doc.scene.shapes(inds);
        updateShapeSelectionDisplay(this);
    end
end

%% Figure management
methods
    function close(this, varargin)
        disp('Close shape viewer frame');
        delete(this.handles.figure);
    end
    
    function onFigureResized(this, varargin)
        updateShapeSelectionDisplay(this);
    end
end


end % end classdef

