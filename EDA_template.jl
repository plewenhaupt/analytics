# 1. Load data
# 2. Check size of data file
# 3. Check size of tabular data (rows and columns)
# 4. Check variables - Columns. Determine type. If not correct type, set column to correct type in dataframe.
# 5. Descriptive statistics of variables:
# 5.1. Ordinal/nominal - Frequency distributions, mode
# 5.2. Continuous/discrete - Mean, median, range, quartiles, variance, standard deviation.
# 5. Check missing - It would be nice to be able to recreate the chart I had in R, showing the missing values. Otherwise, a bar chart showing the proportion of missing, perhaps? No, a heatmap is better, where each square represents part of the dataset.

# Load packages
using
DataFrames,
DataFramesMeta,
Dates,
FreqTables,
GLM,
Missings,
Statistics,
StatsBase,
StatsPlots,
TableView,
XLSX


# Check size of data file
file_path = "/Users/pederlewenhaupt/Misc/data.xlsx"
file_size = filesize(file_path)
kb = file_size/1000
mb = file_size/(1000^2)
filesize_df = DataFrame(bytes = file_size, kilobytes = round(kb, digits = 2), megabytes = round(mb, digits = 2))

# Load data
original_data = @chain file_path XLSX.readtable(_, 1) DataFrame()

#######################################
# DATA INSPECTION AND TYPE FORMATTING #
#######################################
# Check size of tabular data
df_size = DataFrame(rows = nrow(original_data), columns = ncol(original_data))

# Ocular inspection of first 10 rows
first_df = first(original_data, 10)
showtable(first_df)

# List column names
variable_names = @chain original_data names()

# Make a dictionary of question ids and questions
questions = [original_data[1,i] for i in 1:ncol(original_data)]
variable_dict = Dict(variable_names .=> questions)
variable_df = @chain DataFrame(variable_names = variable_names, questions = questions) sort()

# Remove the first row, containing the questions
clean_data = original_data[Not([1]), :]

# Fix empty and missing
for col in variable_names
    clean_data[!, Symbol(col)] = passmissing((x -> x == "-" ? missing : x)).(clean_data[!, Symbol(col)])
end

# Create dictionary of unique values for each variable
unique_values_dict = Dict()
for col in variable_names
    unique_variable_values = @chain clean_data[!, Symbol(col)] unique()
    push!(unique_values_dict, col => unique_variable_values)
end
unique_values_dict = sort(unique_values_dict)

# Create array of data type for each column
variable_type_array = [
"string",
"string",
"string",
"string",
"string",
"int",
"int",
"int",
"int",
"int",
"int",
"int",
"int",
"int",
"int",
"int",
"int",
"int",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"int",
"int",
"int",
"int",
"string",
"int",
"string",
"string",
"int",
"int",
"string",
"int",
"int",
"string",
"string",
"int",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"int",
"int",
"int",
"datetime",
"int",
"int",
"int",
"string",
"int",
"int",
"int",
"int",
"boolean",
"string",
"string",
"int",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"int",
"string",
"date",
"datetime",
"int",
"int",
"string",
"int",
"string",
"date",
"date",
"float",
"date",
"string",
"int",
"int",
"int",
"string",
"float",
"float",
"int",
"string",
"string",
"string",
"int",
"int",
"string",
"int",
"int",
"int",
"int",
"int",
"int",
"int",
"int",
"int",
"string",
"string",
"string",
"string",
"string",
"int",
"int",
"int",
"int",
"string",
"int",
"string",
"float",
"int",
"int",
"int",
"string",
"int",
"string",
"int",
"int",
"datetime",
"string",
"string",
"int",
"int",
"string",
"string",
"int",
"int",
"int",
"date",
"datetime",
"string",
"string",
"string",
"int",
"int",
"int",
"int",
"string",
"string",
"date",
"string",
"string",
"string",
"int",
"int",
"string"
]

unique_types = @chain variable_type_array unique() sort()

# Create dataframe with variables and types
variable_df[!, "type"] = variable_type_array

# Assign the correct types to columns
# The general idea here is to treat each column individually, but if one column with a data type works, why not run a for loop and try the others as well?
# Boolean
#########
# Create array of boolean columns
boolean_columns = @chain variable_df @subset(:type .== "boolean")

# Assign boolean type to columns
for col in boolean_columns.variable_names
clean_data[!, Symbol(col)] = @chain clean_data[!, Symbol(col)] begin
                          string.(_)
                          (x -> x == "1" ? true : false).(_)
                      end
end
println("Boolean columns formatted")
# Date
#########
date_columns = @chain variable_df @subset(:type .== "date")

for col in date_columns.variable_names
    clean_data[!, Symbol(col)] = passmissing(x->Date(x, dateformat"yyyy-mm-dd")).(clean_data[!, Symbol(col)])
end
println("Date columns formatted")
# Datetime
#########
datetime_columns = @chain variable_df @subset(:type .== "datetime")

for col in datetime_columns.variable_names
    clean_data[!, Symbol(col)] = passmissing(x->DateTime(x, dateformat"yyyy-mm-dd HH:MM:SS")).(clean_data[!, Symbol(col)])
end
println("Datetime columns formatted")

# Float
#########
float_columns = []
for (key, value) in variable_dict
    if (value) == "float"
        push!(float_columns, (key))
    end
end

float_columns = sort(float_columns)

for col in float_columns
    df[!, Symbol(col)] = @chain df[!, Symbol(col)] begin
                              passmissing(string).(_)
                              passmissing(parse).(Float64,_)
                          end
end
println("Float columns formatted")

# Int
#########
int_columns = []
for (key, value) in variable_dict
    if (value) == "int"
        push!(int_columns, (key))
    end
end

int_columns = sort(int_columns)

for col in int_columns
    print(col)
    df[!, Symbol(col)] = @chain df[!, Symbol(col)] begin
                              passmissing(string).(_)
                              passmissing(parse).(Float64,_)
                              passmissing(x -> convert(Int64, x)).(_)
                          end
end
println("Int columns formatted")
# String
#########
string_columns = []
for (key, value) in variable_dict
    if (value) == "string"
        push!(string_columns, (key))
    end
end

string_columns = sort(string_columns)

for col in int_columns
    df[!, Symbol(col)] = @chain df[!, Symbol(col)] passmissing(string).(_)
end
println("String columns formatted")

# Check the types
eltype_df = DataFrame(cols = names(df), type = eltype.(eachcol(df)))

########################
# VARIABLE EXPLORATION #
########################
Plots.plotly()
# Boolean columns
boolean_frequency_tables = []
for col in boolean_columns
    frequency = freqtable(df[!, Symbol(col)])
    freq_vec = [frequency[x] for x in 1:2]
    freq_df = DataFrame(col1 = [false, true], n = freq_vec)
    rename!(freq_df, :col1 => col)
    push!(boolean_frequency_tables, freq_df)
end

boolean_frequency_charts = []
for table in boolean_frequency_tables
    colnames = names(table)
    x = Symbol(colnames[1])
    y = Symbol(colnames[2])
    plot = @df table bar(cols(x), cols(y),
                        title = colnames[1],
                        legend = false,
                        size = (1000, 500),
                        xticks = [0, 1])
    push!(boolean_frequency_charts, plot)
end

boolean_plots = plot((boolean_frequency_charts[i] for i in 1:length(boolean_frequency_charts))...,
            layout = (length(boolean_frequency_charts), 1),
            legend = false,
            size = (1000, 500*length(boolean_frequency_charts)))


# Date columns
date_frequency_tables = []
for col in date_columns
    freq_df = @chain df begin
                     groupby(Symbol(col))
                     combine(nrow => :n)
                 end
    push!(date_frequency_tables, freq_df)
end

date_frequency_charts = []
for table in date_frequency_tables
    table = dropmissing(table)
    colnames = names(table)
    x = Symbol(colnames[1])
    y = Symbol(colnames[2])
    plot = @df table bar(cols(x), cols(y),
                        title = colnames[1],
                        legend = false,
                        size = (1000, 500);
                        ticks = :native)
    push!(date_frequency_charts, plot)
end

date_plots = plot((date_frequency_charts[i] for i in 1:length(date_frequency_charts))...,
            layout = (length(date_frequency_charts), 1),
            legend = false,
            size = (1000, 500*length(date_frequency_charts)))



# Datetime columns
datetime_colnames = Symbol.(datetime_columns)
datetime_df = df[!, datetime_colnames]
for col in datetime_columns
    #datetime_df[!, Symbol(col)] =
    datetime_df[!, Symbol(col)] = @chain datetime_df[!, Symbol(col)] begin
                                         passmissing(string).(_)
                                         passmissing(x -> x[1:13]).(_)
                                         passmissing(x -> replace(x, "T" => " ")).(_)
                                         passmissing(x->DateTime(x, dateformat"yyyy-mm-dd HH")).(_)
                                     end
end

datetime_frequency_tables = []
for col in datetime_columns
    freq_df = @chain datetime_df begin
                     groupby(Symbol(col))
                     combine(nrow => :n)
                 end
    push!(datetime_frequency_tables, freq_df)
end

datetime_frequency_charts = []
for table in datetime_frequency_tables
    table = dropmissing(table)
    colnames = names(table)
    x = Symbol(colnames[1])
    y = Symbol(colnames[2])
    plot = @df table bar(cols(x), cols(y),
                        title = colnames[1],
                        legend = false,
                        size = (1000, 500);
                        ticks = :native)
    push!(datetime_frequency_charts, plot)
end

datetime_plots = plot((datetime_frequency_charts[i] for i in 1:length(datetime_frequency_charts))...,
            layout = (length(datetime_frequency_charts), 1),
            legend = false,
            size = (1000, 500*length(datetime_frequency_charts)))


# Float columns
float_frequency_tables = []
for col in float_columns
    freq_df = @chain df begin
                     groupby(Symbol(col))
                     combine(nrow => :n)
                 end
    push!(float_frequency_tables, freq_df)
end

float_describe = describe(df[!, float_columns])

float_frequency_charts = []
for table in float_frequency_tables
    table = dropmissing(table)
    colnames = names(table)
    x = Symbol(colnames[1])
    y = Symbol(colnames[2])
    plot = @df table bar(cols(x), cols(y),
                        title = colnames[1],
                        legend = false,
                        size = (1000, 500);
                        ticks = :native)
    push!(float_frequency_charts, plot)
end

float_plots = plot((float_frequency_charts[i] for i in 1:length(float_frequency_charts))...,
            layout = (length(float_frequency_charts), 1),
            legend = false,
            size = (1000, 500*length(float_frequency_charts)))


# Int columns
int_frequency_tables = []
for col in int_columns
    freq_df = @chain df begin
                     groupby(Symbol(col))
                     combine(nrow => :n)
                     sort()
                 end
    push!(int_frequency_tables, freq_df)
end

int_describe = describe(df[!, int_columns])


int_frequency_charts = []
for table in int_frequency_tables
    table = dropmissing(table)
    colnames = names(table)
    x = Symbol(colnames[1])
    y = Symbol(colnames[2])
    plot = @df table bar(cols(x), cols(y),
                        title = colnames[1],
                        legend = false,
                        size = (1000, 500))
    push!(int_frequency_charts, plot)
end

int_plots = plot((int_frequency_charts[i] for i in 1:length(int_frequency_charts))...,
            layout = (length(int_frequency_charts), 1),
            legend = false,
            size = (1000, 500*length(int_frequency_charts)))


# String columns
# Remove the "Service Q2.2" column, because the name is behaving weirdly
df_colindex = DataFrame(col = string_columns)
deleteat!(string_columns, 66)

string_frequency_tables = []
for col in string_columns
    freq_df = @chain df begin
                     groupby(Symbol(col))
                     combine(nrow => :n)
                     sort(:n)
                 end
    push!(string_frequency_tables, freq_df)
end

string_frequency_charts = []
for table in string_frequency_tables
    table = dropmissing(table)
    colnames = names(table)
    x = Symbol(colnames[1])
    y = Symbol(colnames[2])
    plot = @df table bar(cols(x), cols(y),
                        title = colnames[1],
                        legend = false,
                        size = (1000, 500))
    push!(string_frequency_charts, plot)
end

string_plots = plot((string_frequency_charts[i] for i in 1:length(string_frequency_charts))...,
            layout = (length(string_frequency_charts), 1),
            legend = false,
            size = (1000, 500*length(string_frequency_charts)))
############
# ANALYSIS #
############
# Correlation matrix of int columns
cols = @chain int_columns[[4, 14:18, 20:22, 24:30, 33:37, 42, 56:57, 59:64, 71:76]] vcat(_...)
cor_df = df[!, [Symbol(x) for x in cols]]
corr_matrix = @chain cor_df dropmissing() Matrix() corkendall()
max_val = maximum(abs, M)   # correlation matrix

# Correlation matrix plot
(n,m) = size(corr_matrix)
heatmap(corr_matrix, c = cgrad([:blue,:white,:red]), xticks=(1:m,cols), xrot=90, yticks=(1:m,cols), yflip=true, clims=(-max_val, max_val), size = (1200, 1200))
annotate!([(j, i, text(round(corr_matrix[i,j],digits=2), 8,"Computer Modern",:black)) for i in 1:n for j in 1:m])

# So, what do I do with this correlation matrix?
#- I need p-values for all the correlations
#- Do a hierarchical clustering of all correlations, to see which variables are more highly correlated






# Linear regression with e.g. age, gender, location, etc., as independent values, and the int columns as dependent
lm_df = @chain df begin
                select(:Age, Symbol("Legal Gender"), Symbol("Work Location"), Symbol("Engagement Q2"))
                rename([:Age => :age, Symbol("Legal Gender") => :gender, Symbol("Work Location") => :office, Symbol("Engagement Q2") => :engagement])
                dropmissing()
            end

fm = @formula(engagement ~ age + gender + office)

model = lm(fm, lm_df)

ar = @chain df[!, Symbol("Engagement Q2")] skipmissing() collect()

qqnorm(ar, qqline = :R)

JarqueBeraTest(ar)

# The JB test shows that the dependent variable

poisson_model = glm(fm, lm_df, Poisson(), LogLink())
deviance(poisson_model)

stats = summarystats(col)
stats_dict = Dict(
	:mean => stats.mean,
	:sd => sqrt(var(col)),
	:min => stats.min ,
	:q25 => stats.q25,
	:median => stats.median,
	:q75 => stats.q75,
	:max => stats.max,
	:type => eltype(col),
	:NMissing => nothing,
	:NUnique => nothing
)
