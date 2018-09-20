classdef Shape < handle
%SHAPE Contains information to draw a 2D or 3D shape 
%
%   The shape class ezncapsulates information about the geometry of the
%   shape (as an instance of Geometry class) and drawing options (as an
%   instance of the Style class).
%
%   Example
%   Shape
%
%   See also
%     Geometry2D, Geometry2D, sv.app.Style

% ------
% Author: David Legland
% e-mail: david.legland@inra.fr
% Created: 2018-08-13,    using Matlab 8.6.0.267246 (R2015b)
% Copyright 2018 INRA - BIA-BIBS.


%% Properties
properties
    % a name for uniquely identifying this shape
    name = '';
    
    % the geometry of the shape.
    % stored as an instance of Geometry2D
    geometry;
    
    % the style used to draw this shape, as an instance of sv.app.Style.
    style;
    
    visible = true;
    
end % end properties


%% Constructor
methods
    function this = Shape(varargin)
    % Constructor for Shape class

        if nargin == 1
            this.geometry = varargin{1};
            this.style = Style();
            
        elseif nargin == 2
            this.geometry = varargin{1};
            this.style = varargin{2};
            
        else
            error('Wrong number of arguments for creation of Shape');
        end
    end

end % end constructors


%% Methods
methods
    function varargout = draw(this)
        if ~this.visible
            return;
        end
        
        h = draw(this.geometry, this.style);
        if nargout > 0
            varargout = {h};
        end
    end
end % end methods


%% Serialization methods
methods
    function str = toStruct(this)
        % Convert to a structure to facilitate serialization

        % creates a structure for geometry, including class name
        str.geometry = toStruct(this.geometry);
        if ~isfield(str.geometry, 'type')
            type = classname(this.geometry);
            warning(['geometry type not specified, use class name: ' type]);
            str.geometry.type = type;
        end
        
        % add optional style
        if ~isempty(this.style)
            str.style = toStruct(this.style);
        end
    end
    
    function write(this, fileName, varargin)
        % Write into a JSON file
        savejson('', toStruct(this), 'FileName', fileName, varargin{:});
    end
end

methods (Static)
    function shape = fromStruct(str)
        % Creates a new instance from a structure
        
        % parse geometry
        type = str.geometry.type;
        geom = eval([type '.fromStruct(str.geometry)']);
        shape = sv.app.Shape(geom);
        
        % eventually parse style
        if isfield(str, 'style') && ~isempty(str.style)
            shape.style = sv.app.Style.fromStruct(str.style);
        end
    end
    
    function shape = read(fileName)
        % Read a shape from a file in JSON format
        shape = sv.app.Shape.fromStruct(loadjson(fileName));
    end
end

end % end classdef

