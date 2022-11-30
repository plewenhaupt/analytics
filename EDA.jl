include("ingestion_cleaning.jl")

using
FreqTables

########################
# VARIABLE EXPLORATION #
########################
Plots.plotly()
# Boolean columns
boolean_frequency_tables = []
for col in boolean_columns.variable_names
    frequency = freqtable(clean_data[!, Symbol(col)])
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
for col in date_columns.variable_names
    freq_df = @chain clean_data begin
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
datetime_colnames = Symbol.(datetime_columns.variable_names)
datetime_df = clean_data[!, datetime_colnames]
for col in datetime_columns.variable_names
    #datetime_df[!, Symbol(col)] =
    datetime_df[!, Symbol(col)] = @chain datetime_df[!, Symbol(col)] begin
                                         passmissing(string).(_)
                                         passmissing(x -> x[1:13]).(_)
                                         passmissing(x -> replace(x, "T" => " ")).(_)
                                         passmissing(x->DateTime(x, dateformat"yyyy-mm-dd HH")).(_)
                                     end
end

datetime_frequency_tables = []
for col in datetime_columns.variable_names
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
float_df = clean_data[!, float_columns.variable_names]
float_describe = describe(float_df, :all)

float_frequency_tables = []
for col in float_columns.variable_names
    freq_df = @chain clean_data begin
                     groupby(Symbol(col))
                     combine(nrow => :n)
                 end
    push!(float_frequency_tables, freq_df)
end

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
for col in int_columns.variable_names
    freq_df = @chain clean_data begin
                     groupby(Symbol(col))
                     combine(nrow => :n)
                     sort()
                 end
    push!(int_frequency_tables, freq_df)
end

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
string_frequency_tables = []
for col in string_columns.variable_names
    freq_df = @chain clean_data begin
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
