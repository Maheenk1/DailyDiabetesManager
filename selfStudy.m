function[]=selfStudy()

%Reads table and formats it to contain index, timestamp, event type, &
%value
M=readtable("Clarity_Export_Khan_Maheen_2022-11-15_075542.csv",'NumHeaderLines',0);
patientName=char([M.PatientInfo{1},' ',M.PatientInfo{2}]);
newM=[M(:,1),M(:,2),M(:,3),M(:,8)];

%remove all data points that are not recorded blood-sugar values
for ctr=size(newM,1):-1:1
    if strcmp(newM.EventType{ctr},'EGV')==0
        newM(ctr,:)=[];
    end
end

%Welcome message and prompts to continue
ans1=questdlg(sprintf(['Welcome, %s, to DDM: an interactive Diabetes Daily Management program that analyzes blood sugar events. ' ...
    'Would you like to proceed with the uploaded data?'],patientName));
if strcmp(ans1,'No') || strcmp(ans1,'Cancel')
    disp('Have a nice day.');
    return
elseif strcmp(ans1,'Yes')
    disp('Perfect. Lets get started.');
    disp(' ');
end

%Ask for data
disp('Please provide some data about your treatment methods so that I can better assist you.');
unitValue=input('How many grams of carbohydrates do you take a single unit of insulin for? ');
targetValue=input('What is your target blood sugar value? Please provide values in mg/dl. ');
correctionValue=input('How many mg/dl above your target value do you take a single unit of insulin to correct for? ');
basal=input('Do you take a long-acting form of insulin? On average, how many units of insulin do you take per hour? ');
disp(' ');
disp('Thank you for providing information.');

%Prompt for bolus calculator, provide bolus calculation
ans1=questdlg('Would you like to access the bolus calculator?');
if strcmp(ans1,'Yes')
    currentBS=input('OK. Please provide your current blood sugar reading in mg/dl. ');
    disp(' ')
    if currentBS>=180
        disp('Your current blood sugar reading is high. When factoring calculations we will include a correction dosage.');
    elseif currentBS<=70
        disp('Your current blood sugar reading is low. It is not reccomended that you take any insulin right right now.');
        disp('It is reccomended that you consume 15g of carbohydrates and eat a small meal to reach a healthy range before taking insulin.');
        return
    else
        disp('Your current blood sugar is in a healthy range. ');
    end
    disp(' ');
    carbs=input('How many carbohydrates do you plan on consuming? ');
    if currentBS>targetValue
        correct=(currentBS-targetValue)/correctionValue;
    else
        correct=0;
    end
    bolusCalc=round(((carbs/unitValue)+(correct)),1);
    disp(' ');
    fprintf(['According to the calculations, you should take %d units of insulin to account for your blood sugar and carbohydrate ' ...
        'consumption.'],bolusCalc);
    disp(' ');
    disp('Please note that these rough calculations are not certain. Different foods affect indivduals in different ways.');
    disp(['If you are unsure about your insulin dosages, it is best to consult a doctor. These calculations should only be used as rough ' ...
        'suggestions.']);
end

%Initial insights
inRange=0;
format longG;
for ctr=1:1:size(newM)
    if newM.GlucoseValue_mg_dL_(ctr) >= 70 && newM.GlucoseValue_mg_dL_(ctr) <=180
        inRange=inRange+1;
    end
end

disp(' ');
percentage=inRange/size(newM,1)*100;
date=char(newM.Timestamp_YYYY_MM_DDThh_mm_ss_);
fprintf('On this analyzed day of %s, you were in range (between 70 mg/dl and 180 mg/dl) %s percent of the time. \n',date(1,1:10),num2str(round(percentage),3));
disp(' ');
pause(3)

%comment on range percentages
if percentage<=50
    disp('Although this result may be frustrating, there are various steps you can take to improve your blood sugar levels.');
    disp('You may even just simply be having a bad day. Sometimes those are unavoidable, and it is OK to not be perfect.');
elseif percentage>50
    disp('Good work today! You stayed in range for a majority of the day. That is something to celebrate.');
end

pause(3)

disp(' ');
disp('We will now take a closer look at the trends of your blood glucose.');
disp(' ');

validReadings=newM;

pause(3)

%find average glucose and standard deviation
notNaN=(validReadings{:,4});
notNaN=notNaN(~isnan(notNaN));
averageGlucose=mean(notNaN);
standardDeviation=std(notNaN);
fprintf('Your average glucose for this day was %s.',num2str(averageGlucose));
disp(' ');
fprintf('The standard deviation of your glucose for this day was %s.',num2str(round(standardDeviation,3)));
disp(' ')

pause(5)

disp('According to experts, your standard deviation of blood glucose should be no more than a third of your average glucose.')
disp(' ')

pause(3)

if standardDeviation>(averageGlucose*(1/3))
    disp('By these standards, your standard deviation is outside the desired range.')
    pause(3)
    disp(' ')
    disp('A greater standard deviation can be an indication that you are experiencing numerous hypertensive and hyperglycemic events.')
    disp(['Studies indicate that a greater standard deviation can potentially cause diabetic complications, ' ...
        'so lowering variation should be a priority.'])
    pause(3)
    disp(' ')
    disp('Spikes in blood glucose around mealtimes can be indicative of an insufficient insulin dosage or prebolus.')
    disp(['However, spikes in blood glucose can also be affected by other variables such as physical activity and stress. ' ...
        'They cannot always be controlled.'])
    pause(3)
    disp(' ')
    disp('Dips in blood glucose are typically indicative of an insulin overdose.')
    disp('However, it may also be the result of other variables such as physical exercise.')
    pause(3)
    disp(' ')
    disp("Although spikes and dips in blood glucose cannot always be in one's control, remember to pre-bolus and choose dosages carefully.")
else
    disp('By these standards, your standard deviation is inside the desired range.')
    pause(3)
    disp(' ')
    disp('A lower standard deviation is an indication of greater control, thus reducing the risk of diabetic complications.')
    disp('Great job!')
end


%find highs,slows,fallrates
examinedM=[newM(:,1),newM(:,2),newM(:,4)];
examinedM.Properties.VariableNames = ["index","timeStamp","bloodGlucose"];
for ctr=1:1:size(newM,1)-1
    slope=(examinedM.bloodGlucose(ctr+1)-examinedM.bloodGlucose(ctr))/((examinedM.index(ctr+1)-examinedM.index(ctr))*5);
    if slope>=2
        examinedM.fastRise(ctr+1)=true;
    end
    if slope<=-2
        examinedM.fastFall(ctr+1)=true;
    end
end

for ctr=1:1:size(newM,1)
    if examinedM.bloodGlucose(ctr)>=180
        examinedM.highBS(ctr)=true;
    elseif examinedM.bloodGlucose(ctr)<=70
        examinedM.lowBS(ctr)=true;
    end
end

disp(examinedM)

end