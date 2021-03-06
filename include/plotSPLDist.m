function plotSPLDist(handles)
% Plot del SPL frente a la distancia
% Muestra la curva de SPL frente a distancia segun rango de tiempo
%
% Version 2017.1
% Autor: Jose Manuel Requena Plens
% Email: <a href="matlab:web('mailto:info@jmrplens.com')">info@jmrplens.com</a>
% Telegram: <a href="matlab:web('https://t.me/jmrplens')">@jmrplens</a>

global RecPosition_00 SPLxRec_00 IDFuente Rango GenVideo PrimFotograma
global LimVideoMin LimVideoMax
% Carga en una variable local la variable global de posicion de la fuente
% seleccionada
eval(sprintf('global SRCPosition_%s',IDFuente))
eval(sprintf('SRCPosition = SRCPosition_%s;',IDFuente))

% Calculo de la distancia para cada receptor
Distancia = zeros(1,size(RecPosition_00,1));
for d=1:size(RecPosition_00,1)
    Distancia(d) = sqrt(...
        (RecPosition_00(d,1)-SRCPosition(1))^2+...
        (RecPosition_00(d,2)-SRCPosition(2))^2+...
        (RecPosition_00(d,3)-SRCPosition(3))^2);
end

Distplot = min(Distancia):0.01:max(Distancia); % Vector de distancias para las curvas

% Obtencion del SPL a cada receptor segun la posicion de fuente recibida
Ini = find(strcmp(SPLxRec_00, IDFuente)==1,1);
Fin = find(strcmp(SPLxRec_00, IDFuente)==1,1,'last');
SPLm = SPLxRec_00(Ini:Fin,3:end);

% Separacion e integracion de los niveles antes y despues del rango
SPL0toValM = zeros(1,numel(SPLm));
SPLValtoInfM = zeros(1,numel(SPLm));
for i=1:numel(SPLm)
    
    % En primer lugar agrupa los niveles en bloques de 1 milisegundo, ya que hay
    % varios niveles por milisegundo, y promedia los valores de cada bloque
    for j=1:max(ceil(SPLm{i}(:,1)))
        Ini = find(SPLm{i}(:,1)>=j-1,1); % Inicio del bloque de 'j' milisegundos
        Fin = find(SPLm{i}(:,1)>j,1)-1; % Fin del bloque de 'j' milisegundos
        % Si ha llegado al final del vector, fin estara vacio y inicio y fin
        % seran iguales para obtener el valor ultimo del vector
        if isempty(find(SPLm{i}(:,1)>j,1)); Fin=Ini; end
        % Si el bloque del milisegundo 'j' existe, ini sera menor o igual a fin,
        % si no existe ini sera mayor a fin y no habra valor en ese milisegundo.
        if Ini<=Fin
            Valores = SPLm{i}(Ini:Fin,2:end);
            % Suma el bloque por octavas y vuelve a sumar para obtener un valor
            ValMS(j) = 10*log10(sum(sum(10.^(Valores/10),1)));
        else
            ValMS(j)=NaN; % Este valor se interpola m�s adelante
        end
        
    end
    % Si se utiliza matlab 2014b o anterior realiza la interpolacion
    % manualmente, sino utiliza la funcion fillmising
    if verLessThan('matlab','8.7')
        % Interpolacion manual
        bd=isnan(ValMS);
        gd=find(~bd);
        bd([1:(min(gd)-1) (max(gd)+1):end])=0;
        ValMS(bd)=interp1(gd,ValMS(gd),find(bd));
    else
        % Interpolar valores en los milisegundos que haya valor 0, desde el inicio
        % al final del vector
        ValMS = fillmissing(ValMS,'linear','EndValues','extrap');
    end
    
    SPL0toVal = ValMS(1:Rango);
    SPLValtoInf = ValMS(Rango+1:end);
    
    SPL0toValM(i) = 10*log10(sum(10.^(SPL0toVal/10)));
    SPLValtoInfM(i) = 10*log10(sum(10.^(SPLValtoInf/10)));
    clearvars ValMS
end

% Ejes donde representar
axes(handles.plotfig)

%% Puntos y curva de 0ms a Valor
% Ordenar valores de distancia de menor a mayor manteniendo su valor de SPl
% asociado
Mix1 = sortrows([Distancia',SPL0toValM']);
% Si tiene distancias duplicadas se promedia el nivel de las dos distancias
% iguales y elimina el duplicado
[C,~,idx] = unique(Mix1(:,1),'stable');
val = accumarray(idx,Mix1(:,2),[],@(x) 10*log10(mean(10.^(x/10))));
Mix1 = [C,val];
% A�adir por extrapolacion valor en la posicion de 0 metros hasta la posicion del
% receptor mas cercano
%V0_0toVal=interp1(Mix1(:,1),Mix1(:,2),0,'linear','extrap');
%Mix1 = [[0;V0_0toVal]';Mix1];
% Separar los valores para graficar y convertirlo en vector fila
Dist = Mix1(:,1);
SPLrec = Mix1(:,2);
% Crear curva potencial
[Ucoef,Ures,Uoutput]=fit(Dist,SPLrec,'power1');
Uplot=Ucoef.a*Distplot.^Ucoef.b;
% Muestra los puntos
plot(Dist,SPLrec,'o')
hold on
% Muestra la curva
Curv(1)=plot(Distplot,Uplot,'b');

%% Puntos y curva de valor a infinito ms
% Ordenar valores de distancia de menor a mayor manteniendo su valor de SPl
% asociado
Mix2 = sortrows([Distancia',SPLValtoInfM']);
% Si tiene distancias duplicadas se promedia el nivel de las dos distancias y
% elimina el duplicado
[C,~,idx] = unique(Mix2(:,1),'stable');
val = accumarray(idx,Mix2(:,2),[],@(x) 10*log10(mean(10.^(x/10))));
Mix2 = [C,val];
% A�adir por extrapolacion valor en la posicion de 0 metros hasta la posicion del
% receptor mas cercano
% V0_0toVal=interp1(Mix2(:,1),Mix2(:,2),0,'linear','extrap');
% Mix2 = [[0;V0_0toVal]';Mix2];
% Separar los valores para graficar y convertirlo en vector fila
Dist = Mix2(:,1);
SPLrec = Mix2(:,2);
% Obtener coeificentes curva polinomica de grado 1
[Pcoef,Pres,Poutput] = fit(Dist,SPLrec,'poly1');
% Crea la curva
Pplot = Pcoef.p1*Distplot+Pcoef.p2;
% Muestra los puntos
plot(Dist,SPLrec,'o')
% Muestra la curva
Curv(2)=plot(Distplot,Pplot,'r');

hold off

%% Informacion de las graficas
% A�ade las rejillas de las graficas
grid on
grid minor

% Obtener punto de cruce
CortesInd = find(abs(Uplot-Pplot)<=(0.05));
if ~isnan(CortesInd)
    DistCorte = Vector(CortesInd(1));
    text(DistCorte,Uplot(CortesInd(1)),...
        strcat('\bf\color{black}',[num2str(DistCorte),' m']),...
        'VerticalAlignment','bottom','HorizontalAlignment','left')
end
% Obtener numero de ceros decimales de las pendientes, sumarle 1 y convertir a
% string, para mostrar tantos numeros decimales en las funciones que se ven en
% la leyenda
P11 = num2str(fix(abs(log10(abs(Ucoef.b))))+2);
P21 = num2str(fix(abs(log10(abs(Pcoef.p1))))+2);

leyenda{1} = sprintf(['\\bf0 %s %d ms\\rm   R^2_{adj} = %4.2f\n\\color{blue}y = %4.2f�x^{%4.',P11,'f} \n \\color{white}.'],handles.LWORDTO,Rango,Ures.adjrsquare,Ucoef.a,Ucoef.b);
leyenda{2} = sprintf(['\\bf%d ms %s\\rm   R^2_{adj} = %4.2f\n\\color{red}y = %4.',P21,'f�x+%4.2f \n \\color{white}.'],Rango,handles.LTOINF,Pres.adjrsquare,Pcoef.p1,Pcoef.p2);
lgdw=legend(Curv,leyenda);
% Si se utiliza Matlab 2014b o anterior no a�ade el titulo a la leyenda ya
% que no es compatible
if ~verLessThan('matlab','8.7')
    title(lgdw,handles.LLEGENDSPLDIST)
end
lgdw.FontSize = 11;
ylabel(handles.LLEVELDB)
xlabel(handles.LDISTANCE)
title({[handles.LSPLTITLE,sprintf(' - %d ms',Rango)];...
    ['\color{blue} ',handles.LSUBTITLE,sprintf(': %s',IDFuente)]});

%% Video
% Si se esta realizando un video, se obtiene el maximo y minimo valor desde el
% inicio del video hasta el final y se asignan como limites en el eje y
if GenVideo
    % Si es el primer fotograma del video se calcula los limites de eje para
    % todos los fotogramas
    if PrimFotograma
        for k=1:str2double(get(handles.limvideoms,'String'))
            for i=1:numel(SPLm)
                for j=1:max(ceil(SPLm{i}(:,1)))
                    Ini = find(SPLm{i}(:,1)>=j-1,1); % Inicio del bloque de 'j' milisegundos
                    Fin = find(SPLm{i}(:,1)>j,1)-1; % Fin del bloque de 'j' milisegundos
                    % Si ha llegado al final del vector, fin estara vacio y inicio y fin
                    % seran iguales para obtener el valor ultimo del vector
                    if isempty(find(SPLm{i}(:,1)>j,1)); Fin=Ini; end
                    % Si el bloque del milisegundo 'j' existe, ini sera menor o igual a fin,
                    % si no existe ini sera mayor a fin y no habra valor en ese milisegundo.
                    if Ini<=Fin
                        Valores = SPLm{i}(Ini:Fin,2:end);
                        % Promedia el bloque por octavas y suma los valores por octava del
                        % promedio para obtener un unico valor
                        ValMS(j) = 10*log10(sum(mean(10.^(Valores/10),1)));
                    else
                        ValMS(j)=0;
                    end
                    
                end
                % Todos los valores 0 y menores a 0 se dejan vacios
                ValMS(ValMS<=0) = NaN;
                % Si se utiliza matlab 2014b o anterior realiza la interpolacion
                % manualmente, sino utiliza la funcion fillmising
                if verLessThan('matlab','8.7')
                    % Interpolacion manual
                    bd=isnan(ValMS);
                    gd=find(~bd);
                    bd([1:(min(gd)-1) (max(gd)+1):end])=0;
                    ValMS(bd)=interp1(gd,ValMS(gd),find(bd));
                else
                    % Interpolar valores en los milisegundos que haya valor 0, desde el inicio
                    % al final del vector
                    ValMS = fillmissing(ValMS,'linear','EndValues','extrap');
                end
                
                SPL0toValM(i) = 10*log10(sum(10.^(ValMS(1:k)/10)));
                SPLValtoInfM(i) = 10*log10(sum(10.^(ValMS(k:end)/10)));
                clearvars ValMS
            end
            % Puntos y curva de 0ms a Valor
            % Ordenar valores de distancia de menor a mayor manteniendo su valor de SPl
            % asociado
            Mix1 = sortrows([Distancia',SPL0toValM']);
            % Si tiene distancias duplicadas se promedia el nivel de las dos distancias
            % iguales y elimina el duplicado
            [C,~,idx] = unique(Mix1(:,1),'stable');
            val = accumarray(idx,Mix1(:,2),[],@mean);
            Mix1 = [C,val];
            % A�adir por extrapolacion valor en la posicion de 0 metros hasta la posicion del
            % receptor mas cercano
            V0_0toVal=interp1(Mix1(:,1),Mix1(:,2),0,'linear','extrap');
            Mix1 = [[0;V0_0toVal]';Mix1];
            %% Puntos y curva de valor a infinito ms
            % Ordenar valores de distancia de menor a mayor manteniendo su valor de SPl
            % asociado
            Mix2 = sortrows([Distancia',SPLValtoInfM']);
            % Si tiene distancias duplicadas se promedia el nivel de las dos distancias y
            % elimina el duplicado
            [C,~,idx] = unique(Mix2(:,1),'stable');
            val = accumarray(idx,Mix2(:,2),[],@mean);
            Mix2 = [C,val];
            % A�adir por extrapolacion valor en la posicion de 0 metros hasta la posicion del
            % receptor mas cercano
            V0_0toVal=interp1(Mix2(:,1),Mix2(:,2),0,'linear','extrap');
            Mix2 = [[0;V0_0toVal]';Mix2];
            % Obtener maximos y minimos
            MaxSPL(k) = max(max(Mix1(:,2),Mix2(:,2)));
            MinSPL(k) = min(min(Mix1(:,2),Mix2(:,2)));
            PrimFotograma = false;
            LimVideoMin = min(MinSPL);
            LimVideoMax = max(MaxSPL);
        end
    end
    % Se aplica el limite de ejes calculado en el primer fotograma
    ylim([LimVideoMin-2,LimVideoMax+2])
end
