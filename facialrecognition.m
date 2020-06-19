% CITS4402 Facial Recognition Project Semester 1 2019
% Terence Leong      21707741
% Dickson Hee        21900505
% Vladislav Matveev  21965049

function varargout = facialrecognition(varargin)
% FACIALRECOGNITION MATLAB code for facialrecognition.fig
%      FACIALRECOGNITION, by itself, creates a new FACIALRECOGNITION or raises the existing
%      singleton*.
%
%      H = FACIALRECOGNITION returns the handle to a new FACIALRECOGNITION or the handle to
%      the existing singleton*.
%
%      FACIALRECOGNITION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FACIALRECOGNITION.M with the given input arguments.
%
%      FACIALRECOGNITION('Property','Value',...) creates a new FACIALRECOGNITION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before facialrecognition_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to facialrecognition_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help facialrecognition

% Last Modified by GUIDE v2.5 18-May-2019 15:00:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @facialrecognition_OpeningFcn, ...
                   'gui_OutputFcn',  @facialrecognition_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before facialrecognition is made visible.
function facialrecognition_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to facialrecognition (see VARARGIN)

% Choose default command line output for facialrecognition
handles.output = hObject;
% Change slider step size
maxSlider = get(handles.trainingSlider, 'Max');
minSlider = get(handles.trainingSlider, 'Min');
rangeSlider = maxSlider - minSlider;
stepsSlider = [1/rangeSlider, 10/rangeSlider];
set(handles.trainingSlider, 'SliderStep', stepsSlider);
uistack(handles.uipanel3,'bottom');
set(handles.uipanel3,'visible','on');

% Downsample size
handles.downsampleSize = [10 5];
% Column length q = c*d
handles.len = prod(handles.downsampleSize);
% Default number of image per subject and training/test size
handles.imageCount = [];
handles.trainSize = [];
handles.testSize = [];
handles.phasePercentage = 0.5;


% Open directory for image set, if not selected exit is set
% When file is selected, does not check for correct format
handles.imageFile = uigetdir();
if isequal(handles.imageFile,0)
    handles.exit=true;
    guidata(hObject,handles);
    return
end

% Initialise variables for dataset handling
handles.imageClass = dir(handles.imageFile);
handles.trainFileLoc = zeros(10);
handles.testFileLoc = zeros(10);
handles.trainDataset = zeros(10);
handles.testDataset = zeros(10);
handles.hatMat = 0;

% Read image file and compute hat matrix
handleDataset(hObject, eventdata, handles);
handles=guidata(hObject);
computeHatMat(hObject, handles);
handles=guidata(hObject);
% Update handles structure
recognitionAccuracy(hObject, handles);
guidata(hObject, handles);




% --- Outputs from this function are returned to the command line.
function varargout = facialrecognition_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

if (isfield(handles,'exit') && handles.exit)
      facialrecognition_CloseRequestFcn(hObject, eventdata, handles)
      warning('No file was selected, program will now close!~');
end

% --- Deletes the current figure
function facialrecognition_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to facialrecognition (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% delete(hObject) closes all figures
delete(hObject);

% --- Executes on button press in runButton.
function runButton_Callback(hObject, eventdata, handles)
% hObject    handle to runButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute face recognition with new input parameters from slider
handleDataset(hObject, eventdata, handles);
handles=guidata(hObject);
computeHatMat(hObject, handles);
handles=guidata(hObject);
recognitionAccuracy(hObject,handles);
guidata(hObject,handles);


% --- Executes on slider movement.
function trainingSlider_Callback(hObject, eventdata, handles)
% hObject    handle to trainingSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Set percentage of images to be used for training
sliderValue = round(get(handles.trainingSlider,'Value'));
handles.phasePercentage = sliderValue/10;
set(handles.trainingDisplay,'String',sprintf('%d%%',sliderValue*10));
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function trainingSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trainingSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on button press in changeButton.
function changeButton_Callback(hObject, eventdata, handles)
% hObject    handle to changeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Save previous folder name for 'cancel' selection option
tempFile = handles.imageFile;
handles.imageFile = uigetdir();
if handles.imageFile ~= 0
    handleDataset(hObject, eventdata, handles);
    handles=guidata(hObject);
    computeHatMat(hObject, handles);
    handles=guidata(hObject);
    recognitionAccuracy(hObject,handles);
end
% Change the imageFile back to the previous one
if isequal(handles.imageFile,0)
    handles.imageFile = tempFile;
end
guidata(hObject,handles);

% --- Function to perform image preprocessing
function postImage = imageProcessing(hObject, handles, image)
% Grayscale image if necessary
if size(image,3)==3
    image = rgb2gray(image);
end
% Downsample image to c*d (in this case 20x20)
image = imresize(image,handles.downsampleSize);
% Transform to vector through column concatenation
image = double (reshape(image,handles.len,1));
% Normalise so that maximum pixel value is 1
postImage = image/max(image);

% --- Function to process images used for LRC
function handleDataset(hObject, eventdata, handles)
% Extract class labels from directory names
handles.imageClass = dir(handles.imageFile);
% Remove invalid directory names 
isDir = [handles.imageClass.isdir];
handles.imageClass = {handles.imageClass(isDir).name};
constantFiles = {'.','..'};
[exist,index] = ismember(constantFiles,handles.imageClass);
handles.imageClass(index) = [];
handles.imageCount = [];
handles.trainSize = [];
handles.testSize = [];

for y = 1 : length(handles.imageClass)
    % Extract file path and images
    imageFolder = strcat(handles.imageFile, '/', handles.imageClass{y});
    allImages = [dir(strcat(imageFolder, '/', '*.pgm')); dir(strcat(imageFolder, '/', '*jpg'))];
    isDir = [allImages.isdir];
    allImages = {allImages(~isDir).name};
    handles.imageCount(y) = length(allImages);
    handles.trainSize(y) = round(length(allImages)*handles.phasePercentage);
    handles.testSize(y)=handles.imageCount(y)-handles.trainSize(y);
end

% Allocate space for training/testing image column
% Store image in columns (matrix X_i)
handles.trainDataset = zeros(handles.len, max(handles.trainSize), length(handles.imageClass));
handles.testDataset = zeros(handles.len, max(handles.testSize), length(handles.imageClass));
% Allocate space for training/testing image file path
handles.trainFileLoc = repmat({''}, max(handles.trainSize), length(handles.imageClass));
handles.testFileLoc = repmat({''}, max(handles.testSize), length(handles.imageClass));

% Loop through every subject directory
for i = 1 : length(handles.imageClass)
    % Extract file path and images
    imageFolder = strcat(handles.imageFile, '/', handles.imageClass{i});
    allImages = [dir(strcat(imageFolder, '/', '*.pgm')); dir(strcat(imageFolder, '/', '*jpg'))];
    isDir = [allImages.isdir];
    allImages = {allImages(~isDir).name};
    p = 1;
    % Perform the following for each image
    % Make it so that sorting images to a specified order is not possible
    for j = randperm(handles.imageCount(i))
        % Set image path
        imagePath = strcat(imageFolder, '/', allImages{j});
        % Perform image preprocessing
        postImage = imageProcessing(hObject, handles, imread(imagePath));
        if p <= handles.trainSize(i)
            handles.trainFileLoc{p, i} = imagePath;
            handles.trainDataset(:, p, i) = postImage;
        else
            handles.testFileLoc{p - handles.trainSize(i), i} = imagePath;
            handles.testDataset(:, p - handles.trainSize(i), i) = postImage;
        end
        p = p+1;
    end

end
guidata(hObject, handles);

% Function to compute H_i = X_i * (trans(X_i) * X_i) * trans(X_i)
% Even after grayscaling a coloured image, computation of hat matrix for it
% leads to a warning: Matrix is close to singular or badly scaled. 
function computeHatMat(hObject, handles)
numClass = length(handles.imageClass);
handles.hatMat = zeros(handles.len, handles.len, numClass);
for r = 1 : numClass
    Xi = handles.trainDataset(:, :, r);
    handles.hatMat(:, :, r) = Xi / (Xi' * Xi) * Xi';
end
guidata(hObject,handles);

% Compute the distance between images, find closest distance image
% Compute accuracy of prediction
function recognitionAccuracy(hObject, handles)
correctPre = 0;
current = 1;

for i = 1 : length(handles.imageClass)
    for j = 1 : handles.testSize(i)
        % Compute the predicted vector onto the ith subspace, in other
        % words the closest vector in the euclidean sense to the input
        possibleDist = zeros(length(handles.imageClass), 1);
        for p = 1 : length(possibleDist)
            possibleDist(p) = sum((handles.testDataset(:, j, i) - handles.hatMat(:, :, p) * handles.testDataset(:, j, i)) .^ 2);
        end
        [measuredDist, predictClass] = min(possibleDist);
        
        % Display the test image on the left axis
        axes(handles.axes1);
        imshow(imread(handles.testFileLoc{j, i}));
        
        % Display the predicted image on the right axis
        axes(handles.axes2);
        imshow(imread(handles.trainFileLoc{1, predictClass}));
        
        % Set the correct labels for each parameter and provide loading bar
        % for calculation
        set(handles.text5, 'String', sprintf('Calculating...(%d/%d)', current , sum(handles.testSize)));
        set(handles.text9, 'String', handles.imageClass{i});
        set(handles.text10, 'String', handles.imageClass{predictClass});
        set(handles.text11, 'String', sprintf('%.6f', measuredDist));
        
        % Check for correct image classification, pause for longer if wrong
        if i == predictClass
            correctPre = correctPre + 1;
            pause(0.05);
        else
            pause(0.1);
        end
        current = current + 1;
    end
end

% Return overall recognition accuracy 
recogAcc = correctPre * 100 / sum(handles.testSize);
set(handles.text5, 'String', sprintf('%.2f%%', recogAcc));
% There is a pause here because it is impossible to stop previous execution
% after a new execution has been called, so after a single run is complete,
% it'll go back to the old execution immediately if there is no pause
pause(10);

% Note that the program will not be able to operate properly if there are
% subjects with different number of images i.e. 10 images for one subject
% and 12 for another. This is because the arrays will have empty space
% resulting in hat matrix calculation to mess up when iterating through the
% array






















            
            
            
