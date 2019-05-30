%% Set Parameters: 

clear all 

C1 = 1000; 
C2 = 2500; 
C3 = 5400;

R1 = .00064; 
R2 = .00824;
R3 = .0015; 

R0 = .002402; 
alpha = .65; 
Cbat = 5*3600;  

% C1 = 2400; 
% C2 = 2400; 
% 
% R1 = .015; 
% R2 = .0015;
% R0 = .01; 
% alpha = .65; 
% Cbat = 5*3600;  
% 


Tau1 = C1*R1; 
Tau2 = C2*R2; 
Tau3 = C3*R3; 


dt = .1; 

%%% System Dynamics

% Linear State Dynamics: Dual Polarity Model 

% Continuous Time Model: 
A_c = [0       0         0           0 ; ...
     0  (-1/(R1*C1))     0           0; ... 
     0       0    (-1/(R2*C2))       0; ...
     0       0           0      (-1/(R3*C3))]; 
B_c = [(-1/Cbat); (1/C1); (1/C2); (1/C3) ]; 
C_c = [alpha -1 -1 -1];
D_c = [-R0]; 


Ad = [1      0        0        0; ...
     0 exp(-dt/Tau1) 0         0; ...
     0      0   exp(-dt/Tau2)  0; ...
     0      0        0       exp(-dt/Tau3)];
 
Bd = [(-dt/Cbat); (R1)*(1-exp(-dt/Tau1)); (R2)*(1-exp(-dt/Tau2));(R3)*(1-exp(-dt/Tau3))]; 
Cd = C_c; 
Dd = D_c; 


KalmanParams
% Load Battery Measurements 
load('OCV_table.mat')
load('OCV_slope_table.mat')
load('IV_data_nonlinear.mat')

%%% State/Output Simulation with Process/Measurement Noise (Truth) 

P(1) = 0;           % Covariance 
x1(1) = .98;          % SOC - Battery Fully Charged 
x2(1) = 0;          % Vc1
x3(1) = 0;          % Vc2

x1_hat(1) = x1(1); 

var1 = 3.5*10^-7;
var2 = 1*10^-7;
% var4 = 2*10^-6;
var4 = 1.5*10^-7;

var3 = 0;

for k = 2:1:length(t)
    
    x1(k) = Ad(1,1)*x1(k-1) + Bd(1,1)*I(k-1)+ normrnd(0,.0004); % soc
    x2(k) = Ad(2,2)*x2(k-1) + Bd(2,1)*I(k-1) +normrnd(0,.0); % Vc1
    x3(k) = Ad(3,3)*x3(k-1) + Bd(3,1)*I(k-1)+ normrnd(0,.0); % Vc2
    x4(k) = Ad(4,4)*x3(k-1) + Bd(4,1)*I(k-1)+ normrnd(0,.0); % Vc2

    
    V_truth(k) = interp1(soc_intpts_OCV',OCV_intpts,x1(k-1)) - I(k)*R0 - x2(k)- x3(k) -x4(k) + normrnd(0,sqrt(R));
end 

figure()
hold on 
plot(t,x1)
plot(t,SOC_act)
legend('Simulated Truth','Lin_SOC_act');

figure(); 
plot(t,V_truth)

%% NaN Determination for Preventing Interpolation Fuckups

thing = isnan(V_truth);
% thing = isnan(x1);
% thing = isnan(V);


counter =0; 
for k=1:length(t)
    if thing(k)==1
       display('yes') 
       
       counter = counter +1;
       
    end     
end 

counter



%% NAN Correction 

for u = 1:length(t)
    if thing(u) == 1
        V_truth(u)  = 0; 
        
    end
    
    
    
end 

%% FINAL SOC Correction: 

for O = 1:length(t)
    if SOC_act(O) >1
        SOC_act(O) = 1; 
        
    end 
    
    
end 


%% Third Order Truth

%% Relabel New truth Data

clear V SOC_act 

V = V_truth; 
SOC_act = x1;

V = V'; 
SOC_act = SOC_act'; 

%%

save('C:\Users\felip\Documents\298-Estimation-Theory\J2_EKF_model\DataFiles\Sim_Truth_ThirdOrder_Corrected1.mat','V','SOC_act','t','I'); 


%% 
hold on 
plot(t,SOC_act)