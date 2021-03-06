
library("ggplot2")
library("dplyr")
library("GGally")
library("psych")
library("tidyverse")
library(rio)
set.seed(0)
data = import("C:/Users/dPetr1/Downloads/prep_data1.csv")
head(data)
# Я хочу изучить, как связаны темпы экономического роста и региональные дисбалансы (темпы роста доли городского населения).
# Для этого в качестве зависимой переменной я беру темп прироста ВВП.
data[,5]
df <- data
head(df)
# перед тем как создавать бинарные и нелинейные переменные посмотрим на исходные данные более пристально
is.vector(df$growth)
plot(df$Growth)
is.vector(df$urban)
plot(df$urban)
is.vector(df$population)
plot(df$population)
is.vector(df$trade)
plot(df$trade) # здесь явно что-то не так с данными
is.vector(df$fertility)
plot(df$fertility)
is.vector(df$pop_dens)
plot(df$pop_dens)
summary(df)
df1 <- as.numeric(df)
df$growth <- as.numeric(df$growth)

# Применив такой код на исходных данных я выявил несколько проблем
# Во-первых, данные имеют разный формат, много не численных переменных
# Во-вторых, данные довольно грязные, есть символы (например, "...", "-~8" и другие) вместо значений
# В-третьих, несколько раз встречается знаечние -99, которое не соотносится с признаком на идейном уровне. Посмотрим на это более пристально позже
# В-четвертых, признаков очень много, поэтому смотреть на них в R не очень удобно

# Поэтому как настоящий дата саентист я решил воспользоваться двумя языками программирования. Питоном - для предобработки данных, и затем R - для их анализа.
# Загруженный здесь файл (prep_data1.csv) это уже предобработанный файл из Питона. Для него есть отдельный Юпитер ноутбук.
# Здесь крастко поясню то, что я делал в Питоне, и для чего это нужно

# Сначала я посмотрел на данные и их тип. Детальнее увидел, что есть признаки численные и объекты
# Далее я взял признаки, которые используются для текущей исследовательской задачи 
# Затем я привел данные к нормальному виду (заменил черточки, кружочки и прочее на NA или соответствующие значения)
# После изменил формат объектов на численный
# Наконец сформировал датафрейм из нужных признаков, предварительно изменив названия признаков на более простые 

# В качестве непрерывных регрессоров я беру темп роста доли городского населения, детородность женщин, темп роста населения, логарифм плотности населения. В каестве бинарной переменной беру сальдо торгового баланса. ( 1 - если страна экспортер, 0 - если импортер)
# Темп роста доли городского населения показывает переток наесления из деревень в города, тем самым показывая региональные дисбалансы
# Детородность женщин также может отражать уровень развитости страны, при этом в деревнях и городе данный показатель может разниться
# Темп роста населения говорит о внутренних процессах, большее количество населения может вносить дополнительный вклад в ВВП, как при интенсивном, так и при экстенсивном росте№
# Плотность населений также может отражать дисбалансы между различными регионами. При этом стоит взять логарифм, так как между различными странами очень большая разница. Где-то есть леса, где-то пустыни, поэтому абсолютные значения могут отражать ситуацию не лучшим образом.
# Сальдо торгового баланса интересно, так как мы рассматриваем конкретные года. Общая экономическая конъюнктура может говорить о том, что в этот год определенная торговая политика может лучше влиять на рост экономики


# Посмотрим на матрицу корреляций
cor(df)
library("corrplot")
df  <- df[complete.cases(df),]
# Видно, что корреляция между темпами экономического роста и долей городских жителей, торговым балансов, детородностью енщин и темпом роста населения  колеблется от 0.14 до 0.43 - довольно приличные знаечения

# Теперь посмотрим визуально на признаки
qplot(data = df, Growth, fill ="brick", binwidth = 1, xlab = "Темп экономического роста", ylab = "Количество наблюдений", main = "Плотность распределения темпов экономического роста")
qplot(data = df, Urban, fill ="brick", binwidth = 1, xlab = "Темп роста доли городского населения", ylab = "Количество наблюдений", main = "Плотность распределения темпов роста доли городского населения")
qplot(data = df, Trade, fill ="brick", binwidth = 1, xlab = "Сальдо торгового баланса", ylab = "Количество наблюдений", main = "Плотность распределения сальдо торгового баланса")
qplot(data = df, Fertility, fill ="brick", binwidth = 1, xlab = "Детородность женщин", ylab = "Количество наблюдений", main = "Плотность распределения детородности женщин")
qplot(data = df, Pop_growth, fill ="brick", binwidth = 1, xlab = "Темп роста населения", ylab = "Количество наблюдений", main = "Плотность распределения темпов роста населения")
qplot(data = df, Pop_dens, fill ="brick", binwidth = 1, xlab = "Плотность населения", ylab = "Количество наблюдений", main = "Плотность распределения плотности населения")
qplot(data = df, log(Pop_dens), fill ="brick", binwidth = 1, xlab = "Логарифм плотности населения", ylab = "Количество наблюдений", main = "Плотность распределения логарифма плотности населения")

# Видно, что в данных есть сильные выбросы в отрицательную сторону. Заметно, что много значений -99, вряд ли так много одинаковых значений, да и рост ВВП -99% кажется странным, поэтому буду интерпретировать такие значения как пропущенные данные.
# Кажется, что заменить данные средним не лучший вариант, так как для пропуска могут быть определенные причины - например, отсуствие расчета статистики. Поэтому такие данные будут удалены.

ind <- which(df %in% boxplot.stats(df)$out)
df <- df %>% filter(Growth != -99.0)
df <- df %>% filter(Fertility != -99.0)
df
# С 222 наблюдений мы перешли к 198
# также посмотрим на диаграммы рассеяния
qplot(data = df, Urban, Growth, fill ="brick", binwidth = 1, xlab = "Темп роста доли городского населения", ylab = "Темп экономического роста", main = "Зависимость темпов экономического роста от  доли городского населения")
qplot(data = df, Trade, Growth, fill ="brick", binwidth = 1, xlab = "Сальдо торгового баланса", ylab = "Темп экономического роста", main = "Зависимость темпов экономического роста от сальдо торгового баланса")
qplot(data = df, Fertility, Growth, fill ="brick", binwidth = 1, xlab = "Детородность женщин", ylab = "Темп экономического роста", main = "Зависимость темпов экономического роста от  детородности женщин")
qplot(data = df, Pop_growth, Growth, fill ="brick", binwidth = 1, xlab = "Темп роста населения", ylab = "Темп экономического роста", main = "Зависимость темпов экономического роста от  темпов роста населения")
qplot(data = df, Pop_dens, Growth, fill ="brick", binwidth = 1, xlab = "Плотность населения", ylab = "Темп экономического роста", main = "Зависимость темпов экономического роста от  плотности населения")
qplot(data = df, log(Pop_dens), Growth, fill ="brick", binwidth = 1, xlab = "Логарифм плотности населения", ylab = "Темп экономического роста", main = "Зависимость темпов экономического роста от  логарифма плотности населения")

# протестируем модель
model <- lm(data = df, Growth ~ Urban + Fertility + Trade + Pop_growth + log(Pop_dens))
summary(model)

# Дальше я немного отойду от задания и попробую еще некоторые модели.
# Однако именно model будет исходной моделью для дальнейшей работы

#теперь заменим -99 (пропущенные значения) медианой по соответствующему признаку. Это позволит обучать модель на большей выборке
data2 = import("C:/Users/dPetr1/Downloads/prep_median.csv")
modelm = lm(data = data2, Growth ~ Urban + Fertility + Trade + Pop_growth + log(Pop_dens))
summary(modelm)




library("car")
vif(model)

modelX <- lm(data = df, Growth ~ Urban + Urban^2 + Urban^3 + Urban*Fertility)
summary(modelX)
modelU <- lm(data = df, Growth ~ Urban)
summary(modelU)

mean(df$Growth)
df$Growth <- as.data.frame(lapply(df$Growth, function(x){replace(x, x = -99.0,mean(df$Growth))}))
df    
df[df==-99.9] <- NA
ind<- apply(df, 1, function(x) sum(is.na(x))) > 0
df
# модель себя не оправдала, добавим еще признаки
df2 = import("C:/Users/dPetr1/Downloads/prep_data2.csv")
df2 <- df2 %>% filter(Growth != -99.0)
df2 <- df2 %>% filter(Fertility != -99.0)
df2
library("caret")
dmy <- dummyVars(" ~ .", data = df2)
df3 <- data.frame(predict(dmy, newdata = df2))
df3
model3 <- lm(data = df3, Growth ~ Urban + Industrialization + Urban*Industrialization + RegionWesternEurope)
summary(model3)
model4 <- lm(data = df3, Growth ~ Urban + Industrialization)
summary(model4)

library("memisc")
library("lmtest")
library("foreign")
library("vcd")
library("hexbin")
library("pander")
library("sjPlot")
library("tidyverse")
library("knitr")
resettest(model)
# F критическое при аналитическом расете получается 1.7 на уровне значимости 10%
summary(model4)
resettest(model4) 
summary(data)

# Задание 4
# Для проверки мультиколлинеарности рассмотрим VIF и индекс обусловленности. При наличии мультиколлинеарности оценки будут состоятельными и эффективными, но коэффициенты регрессии будут незначимыми. В таком случае стоит использовать метод главных компонент.
vif(model)
# Значения VIF не превышают 4, так что мультиколлинеарности нет, можно продолжать работать с моделью
library(olsrr)
ols_coll_diag(model)
# максимальное значение CI = CN = 12, что допустимо, так что мультиколлинеарности нет, можно продолжать работать с моделью

# Для проверки гетероскедастичности можно использовать следующие тесты: Голдфельда-Квандта, Уайта, Бройша-Пагана. При наличии гетероскедастичности оценки становятся состоятельными, но неэффективными. Для борьбы с гетероскедастичностью стоит использовать оценки Уайта.
# Тест Голдфельда-Квандта
gqtest(model, order.by = ~Urban, data = df, fraction = 0.2)
gqtest(model, order.by = ~Fertility, data = df, fraction = 0.2)
gqtest(model, order.by = ~Pop_growth, data = df, fraction = 0.2)
gqtest(model, order.by = ~log(Pop_dens), data = df, fraction = 0.2)
# Согласно тесту гетероскедастичность значима для всех признаков кроме логарифма плотности населения

# Тест Бройша-Пагана
bptest(model)
# нулевая гипотеза о гомоскедастичности отвергается, так как p-value высокое

# Для проверки эндогенности можно использовать тест хаусмана. При наличии эндогенности оценки будут смещенными и несостоятельными. Для решения проблемы эндогенности можно использовать двухшаговый МНК и метод инструментальных переменных.

# Тест Хаусмана

# Задание 5
# МНК
summary(model)
# У регрессии очень малй R квадрат, все коэффициенты получились незначимыми. Но коэффициент темпа прироста доли городского населения значм на уровне 11 процентов, помимо этого если уменьшить количесвто признаков он будет значим на более низком уровне.
# Тем роста доли городского населения положительно влияет на темы экономического роста. Производительность факторов производства в городе выше, выше и вклад в экономический рост. При увеличении показателя на 1 процентный пункт, тем экономического роста увеличивается на 0.6 процентных пункта. То есть вклад показателя действительно большой
# В целом можно было бы также как и в дз А использовать ошибки в форме Уайта.

# Стоит также отметить, что детородность и темп роста населения влияют на темп роста доли городского населения
model_urban <- lm(data = df, Urban ~ Fertility + Trade + Pop_growth + log(Pop_dens))
summary(model_urban)

# Незначимость сальдо торгового баланса можно объяснить тем, что видимо в рассматриваемого периоде не было такого общеэкономического фактора, который мог бы повлиять на важность именно направления потоков торговли, поэтому важным остается именно само значение признака

# Двухшаговый МНК
library("dplyr")  # манипуляции с данными
library("caret")  # стандартизованный подход к регрессионным и классификационным моделям
library("AER")  # инструментальные переменные
library("ggplot2")  # графики
library("sandwich")  # робастные стандартные ошибки
library("ivpack")  # дополнительные плющки для инструментальных переменных
library("memisc") 
library(ivmodel)
library(ivpack)
library(MASS)
model_iv <- ivreg(data = df, Growth ~ Urban + Fertility + Trade + Pop_growth + log(Pop_dens) | Urban + Fertility + Trade + Pop_growth + log(Pop_dens))
coeftest(model_iv) 
# результаты очень схожи с результатми МНК
# Попробуем с помощью Уайта
vcovHC(model, type = "HC0")
# Получим робастные ошибки ковариационной матрицы, устойчивые к гетероскедастичности
coeftest(model, vcov. = vcovHC(model))
# сравним в оценками МНК
coeftest(model)
# значимость коэффициентов не улучшилась

# machine learning
# Задание 6 
# Сначала нужно будет разбить выборку на обучение и контроль
in_train <- createDataPartition(y = df$Growth, p = 0.8, list = FALSE)
h2_train <- df[in_train, ]  # это будет обучающейся частью выборки
h2_test <- df[-in_train, ]  # это будет тестовой частью выборки

# Модель 1 - это модель МНК, которую мы использовали изначально. Проведем ее обучение
model_1 <- lm(data = h2_train, Growth ~ Urban + Fertility + Trade + Pop_growth + log(Pop_dens))
lambdas <- seq(50, 0.1, length = 222)
y <- df$Growth  # в вектор y поместим зависимую переменную
# еще раз создадим матрицу регрессоров без свободного члена
X0 <- model.matrix(data = h2_train, Growth ~ 0 + Urban + Fertility + Trade + Pop_growth + log(Pop_dens))
library(glmnet)

model_3 <- lm(data = h2_train, Growth ~ 0 + Urban + Fertility + Trade + Pop_growth + log(Pop_dens))
model_4 <- lm(data = h2_train, Growth ~ 0 + Urban + Fertility + Pop_growth + log(Pop_dens))
m_lasso <- glmnet(X0, y, alpha = 1, lambda = lambdas)
# Построим прогноз для модели
pred_1 <- predict(model_1, h2_test)
pred_2 <- predict(m_lasso, h2_test)
pred_3 <- predict(model_3, h2_test)
pred_4 <- predict(model_4, h2_test)
# Теперь посчитаем метрику (сумма квадратов отклонения ошибок)
sum((pred_1 - h2_test$Growth)^2)
sum((pred_3 - h2_test$Growth)^2)
sum((pred_4 - h2_test$Growth)^2)

# с помощью отбора признаков удалось снизить ошибку в mofel_3 и model_4

# Временные ряды

library("lubridate")  
library("zoo")  
library("xts")  
library("dplyr")  
library("ggplot2")  
library("forecast")
library(fable)
library(feasts)

# Задание 1
# симулируем процесс AR(1) y_t=0.8y_{t-1}+\e_t
y <- arima.sim(n = 120, list(ar = 0.8))
plot(y)  # график ряда
Acf(y)
Pacf(y)
tsdisplay(y)
# (1 - 0.8L)y_t = ...
# Аналитическое решение показывает, что корень лагового многочлена равен 1.25, что больше единицы. Поэтому есть назад смотрящее стационарное решение.

# симулируем процесс AR(3) y_t=0.1y_{t-1}+0.2y_{t-2}+0.3y_{t-3}\e_t
y <- arima.sim(n = 120, list(ar = 0.1, 0.2, 0.3))
plot(y)  # график ряда
Acf(y)
Pacf(y)
tsdisplay(y)
# lambda^3 - 0.1lambda^2 - 0.2lambda - 0.3 = 0 
# Аналитическое решение показывает, что корень характеристического уравнения равен 0.8076, что меньше единицы. Поэтому есть назад смотрящее стационарное решение.

# симулируем процесс MA(2) y_t=\e_t+1.2\e_{t-1}+2\e_{t-2}
y <- arima.sim(n = 120, list(ma = 1.2, 2))
tsdisplay(y)
# Процесс стационарен, так как аналитическое решение показывает мат ожидание и дисперсию как константы

# Задание 2

# симулируем процесс ARIMA(0,0,0)
y <- arima.sim(n = 120, list(order = c(0, 0, 0)))
tsdisplay(y)
# Стационарное решение имеется acf, pacf малы и в рамках промежутка 

# симулируем процесс ARIMA(3,0,0)
y <- arima.sim(n = 120, list(ar = 0.6, 0.9, 2))
tsdisplay(y)
# Ряд стационарен, acf и pacf убывают довольно быстро

# Задание 3

# симулируем процесс случайного блуждания y_t=y_{t-1}+\e_t
y <- arima.sim(n = 120, list(order = c(0, 1, 0)))
tsdisplay(y)
# Данный процесс стационарен, так как визуально значения функций ACF и PACF убывает быстро

# Задание 4 
# Посмотрим на модель случайного блуждания и на модель AR(1) из первого задания
y1 <- arima.sim(n = 120, list(ar = 0.8))
y2 <- arima.sim(n = 120, list(order = c(0, 1, 0)))
Acf(y1)
Acf(y2)
# Для случайного блуждания функция ACF убывает медленнее, чем для выбранного AR ряда
Pacf(y1)
Pacf(y2)
# Функции PACF для рядов довольно схожи, однако для случайного блуждания разброс значений меньше

# Задание 5
# симулируем процесс ARIMA(2,0,3)

y3 <- arima.sim(n = 120, list(ar = 0.1, 0.2, ma = 0.5, 0.6, 0.7))
tsdisplay(y3)

# разделим выборку на обучение и контроль
train <- ts(y3, start =1, end = 99)
test <- ts(y3, start = 100, end = 120)

# Оценим модель на обучающей выборке
fit <- arima(train, order = c(2, 0, 3))

# Построим прогноз на 20 периодов вперед
predict <- forecast(fit, h = 20)

# Сравним результаты
par(mfrow=c(2, 1))
plot(y3)
plot(predict)
