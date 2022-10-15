local parser = {}

--Ввод данных из файла в переменные Order, Constructors, Variables и массив Rules
--В результате получаем bool Order, правые части Constructors и Variables без пробелов, все правила без пробелов
local function inputFromFile(path)
    local file = io.open(path, "r")
    io.input(file)
    local i = 0

    while i < 3 do
        local s = io.read()
        s = string.gsub(s, "%s+", "")
        if s == nil or #s == 0 then goto continue end 
        if s == "lexicographic" or s == "antilexicographic" then
            Order = string.gsub(s, "%s+", "")
            i = i + 1
        elseif s.find(s, "constructors=") ~= nil then
            Constructors = string.gsub(s, "%s+", "")
            i = i + 1
        elseif s.find(s, "variables=") ~= nil then
            Variables = string.gsub(s, "%s+", "")
            i = i + 1
        else 
            error("Error_inputFromFile: unexpected line - " .. s)
        end 
        ::continue::
    end

    Rules = {}
    local count = 1
    while true do
        local s = io.read()
        if s == nil then break end
            local s = string.gsub(s, "%s+", "")
            if #s ~= 0 then 
                Rules[count] = string.gsub(s, "%s+", "")
                count = count + 1
            end
    end
    print(#Rules, "AHAHHA")
    io.write(Order, '\n',Constructors, '\n', Variables, '\n')
    for i = 1, count, 1 do
        if Rules[i] ~= nil then
            io.write(Rules[i], '\n') 
        end
    end
    io.close(file)

    if Order == "lexicographic" then
        Order = true
    elseif Order == "antilexicographic" then
        Order = false
    end

    local Constructors = string.gsub(Constructors, "constructors=", '')

    local Variables = string.gsub(Variables, "variables=", '')
    
    return Order, Constructors, Variables, Rules
end

--Creates structure: {ch char, n int}
--Represents constructors 
local function parseConstructors(Constructors)
    local past = "none"
    local past_ch = ''
    local list = {}
    local len = #Constructors
    for i = 1, len, 1 do
        local ch = string.sub(Constructors, i, i)
        if string.find(ch, "%a") ~= nil and (past == "none" or past == ',') then
            past_ch = ch
        elseif ch == '(' and string.find(past, "%a") == nil then
            error("Error_parseConstructors: expected '(' after letter")
        elseif string.find(ch, "%d") ~= nil and past == '(' then
            table.insert(list, {ch = past_ch, n = tonumber(ch) })
        elseif ch == ')' and string.find(past, "%d") == nil then
            error("Error_parseConstructors: expected digit before ')'") 
        elseif ch == ',' and past ~= ')' then
            error("Error_parseConstructors: expected ')' before ','")
        end
        past = ch
    end
    return list
end

--Adds to Constructors structure: {ch char, 0}
--Represents variables
local function parseVariables(Variables, list) 
    local past = "none"
    local len = #Variables
    for i = 1, len, 1 do
        local ch = string.sub(Variables, i, i)
        if string.find(ch, "%a") ~= nil and (past == "none" or past == ',') then
            table.insert(list, {ch = ch, n = 0 })
        elseif string.find(past, "%a") == nil and ch ~= ',' then
            error("Error_parseVariables: unexpected situation: " .. ch .. " " .. past)
        end
        past = ch
    end
    return list
end

-- Поиск конструктора{char, number} с помощью буквы 
function parser.findConstructor(ch, Constructors) 
    for i = 1, #Constructors, 1 do
        if Constructors[i].ch == ch then
            return Constructors[i]
        end
    end
    return nil
end

function parser.FindRule(root, rule)
    if root.left_child ~= nil and root.left_child.rule == rule then
        return root.left_child
    end
    if root.right_child ~= nil and root.right_child.rule == rule then
        return root.right_child
    end    
    if root.left_child ~= nil then
        return parser.FindRule(root.left_child, rule)
    end
    if root.right_child ~= nil then
        return parser.FindRule(root.right_child, rule)
    end
    return nil
end

-- Разделить строку по подстроке
function mysplit (inputstr, sep)
    if sep == nil then
       sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
       table.insert(t, str)
    end
    return t
 end
-- 
local function parseRule(rule, root, Constructors)
    print(rule)
    root.rule = rule
    local n = parser.findConstructor(string.sub(rule,1,1), Constructors).n
    if n ~= 0 then
        local leftrule = ""
        local rightrule = ""
        local past = "none"
        local past_ch = "none"
        local pcounter = 0
        local leftpar = string.find(rule, "%(")
        local rightpar 
        for i = 1, #rule, 1 do
            local ch = string.sub(rule, i, i)
            if ch == ')' then
                rightpar = i
            end
        end
        local middle_comma = -1
        local n = parser.findConstructor(string.sub(rule,1,1), Constructors).n 
        local butchered_rule = string.sub(rule, leftpar+1, rightpar-1)
        if n == 2 then
            for i = 1, #rule, 1 do 
                local ch = string.sub(butchered_rule, i, i)
                if ch == '(' then
                    pcounter = pcounter + 1
                elseif ch == ')' then
                    pcounter = pcounter - 1
                end
                if pcounter == 0 and ch == ',' then
                    middle_comma = i
                    break
                end
            end
            Left_child = {parent = root, left_child = nil, right_child = nil, rule = nil}
            root.left_child = Left_child
            print(string.sub(butchered_rule, 1, middle_comma - 1), string.sub(butchered_rule, middle_comma + 1), root.rule, "here")
            parseRule(string.sub(butchered_rule, 1, middle_comma - 1), Left_child, Constructors)
            Right_child = {parent = root, left_child = nil, right_child = nil, rule = nil}
            root.right_child = Right_child
            parseRule(string.sub(butchered_rule, middle_comma + 1, #butchered_rule), Right_child, Constructors)
        elseif n == 1 then
            Left_child = {parent = root, left_child = nil, right_child = nil, rule = nil}
            root.left_child = Left_child
            parseRule(string.sub(butchered_rule, 1, #butchered_rule), Left_child, Constructors)
        end
    end
end

local function parseRules(Constructors, Rules)
    local roots = {}
    for i = 1, #Rules, 1 do
        local indl, indr = string.find(Rules[i], "::=")
        local left = {parent = nil, left_child = nil, right_child = nil, rule = nil}
        local right = {parent = nil, left_child = nil, right_child = nil, rule = nil}

        Root = {parent = nil, left_child = left, right_child = right, rule = Rules[i]}
        table.insert(roots, Root)
        local split = mysplit(Rules[i], "::=")
        local _, str = ipairs(split)
        print(#Rules, Rules[1], Rules[2])
        parseRule(str[1], left, Constructors) 
        parseRule(str[2], right, Constructors) 
    end
    return roots
end

local function drawBranch(root) 
    if root.rule ~= nil then
        if root.left_child ~= nil and root.left_child.rule ~= nil then
            io.write("\t\"" .. root.rule .. "\" -> \"" .. root.left_child.rule .. "\"\n")
        end
        if root.right_child ~= nil and root.right_child.rule ~= nil then
            io.write("\t\"" .. root.rule .. "\" -> \"" .. root.right_child.rule .. "\"\n")
        end
        if root.left_child ~= nil and root.left_child.rule ~= nil then
            drawBranch(root.left_child)
        end
        if root.right_child ~= nil and root.right_child.rule ~= nil then
            drawBranch(root.right_child)
        end
    end
end
function parser.DrawTree(tree) 
    io.write("digraph G {\n")
    drawBranch(tree)
    io.write("}")
    io.write("\n")
end

function parser.parse(filepath)
    Order, Constructors, Variables, Rules = inputFromFile(filepath)
    Constructors = parseConstructors(Constructors)
    Constructors = parseVariables(Variables, Constructors)
    Rules = parseRules(Constructors, Rules)
    return Order, Constructors, Rules
end
return parser