

local parser = require "parser"
local function print_bigger(bigger, Constructors) 
    for i = 1, #Constructors, 1 do
        for j = 1, #bigger[Constructors[i].ch].ch, 1 do
            io.write(Constructors[i].ch .. " > " .. bigger[Constructors[i].ch].ch[j] .. "\n")
        end
    end
end
local function check_lex(rule1, rule2, rule, bigger, Constructors)
    local parser = require "parser"
    local i = 1
    local r1 = string.sub(rule1.rule, 3, #rule1 - 1)
    local r2 = string.sub(rule2.rule, 3, #rule2 - 1)
    while string.sub(rule1.rule, i, i) == string.sub(rule2.rule, i, i) and i ~= #rule1.rule do i = i + 1 end
    if i == #rule1.rule then return false, bigger end
    local pcount = 0
    local save_i = i
    while (i < save_i + 2 or pcount > 0) and i < #rule1.rule do
        ch = string.sub(rule1.rule, i, i)
        if i < save_i + 2 and ch == ',' then break end
        if ch == '(' then pcount = pcount + 1 end
        if ch == ')' then pcount = pcount - 1 end
        i = i + 1
    end
    if pcount < 0 then i = i - 1 end
    local subrule1 = string.sub(rule1.rule, save_i, i - 1)
    i = save_i
    pcount = 0
    while (i < save_i + 2 or pcount > 0) and i < #rule2.rule do
        ch = string.sub(rule2.rule, i, i)
        if i < save_i + 2 and ch == ',' then break end
        if ch == '(' then pcount = pcount + 1 end
        if ch == ')' then pcount = pcount - 1 end
        i = i + 1
    end
    if pcount < 0 then i = i - 1 end
    local subrule2 = string.sub(rule2.rule, save_i, i - 1)
    local frule1 = parser.FindRule(rule1, subrule1)
    local frule2 = parser.FindRule(rule2, subrule2)
    if frule1 == nil or frule2 == nil then
        error("Error_chechk_lex: nil rule from FindRule")
    else
        io.write("\"Order:\n")
        print_bigger(bigger, Constructors)
        io.write("\tRule: " .. rule1.rule .. " -> " .. rule2.rule .. "\"\n")
        io.write("\t -> \n\"Order:\n")
        print_bigger(bigger, Constructors)
        io.write("\tRule: " .. frule1.rule .. " -> " .. frule2.rule .. "\"\n")
        io.write("\t[label = " .. "\"KB4(lex) " .. rule1.rule .. " -> " .. rule2.rule .. "\"][color=red];\n")
        return check(frule1, frule2, rule, bigger, Constructors)
    end
end
local function findTableItem(ch, arr) 
    if arr == nil then return false end
    for i = 1, #arr, 1 do
        if arr[i] == ch then
            return true
        end
    end
    return false
end

local function check_bigger(bigger, Constructors) 
    for i = 1, #Constructors, 1 do
        for j = 1, #bigger[Constructors[i].ch].ch, 1 do
            local sym = bigger[Constructors[i].ch].ch[j]
            if findTableItem(Constructors[i].ch, bigger[sym].ch) then return false end
        end
    end
    return true
end
local function saveBigger(bigger, Constructors)
    local new_bigger = {} 
    for i = 1, #Constructors, 1 do
        new_bigger[Constructors[i].ch] = {ch = {}}
        for j = 1, #bigger[Constructors[i].ch].ch , 1 do
            local pos = #new_bigger[Constructors[i].ch].ch + 1
            table.insert(new_bigger[Constructors[i].ch].ch, pos, bigger[Constructors[i].ch].ch[j])
        end
    end
    return new_bigger
end
local function KB1(l_rule, r_rule)
    if l_rule.left_child ~= nil and l_rule.left_child.rule == r_rule.rule then
        return true
    end
    if l_rule.right_child ~= nil and l_rule.right_child.rule == r_rule.rule then
        return true
    end
    return false
end

local function KB2(l_rule, r_rule, rule, bigger, Constructors)
    local res = false
    local saved_bigger = saveBigger(bigger, Constructors)
    if l_rule.left_child ~= nil then
        io.write("\"Order:\n")
        print_bigger(saved_bigger, Constructors)
        io.write("\tRule: " .. l_rule.rule .. " -> " .. r_rule.rule .. "\"\n")
        io.write("\t -> \n\"Order:\n")
        print_bigger(bigger, Constructors)
        io.write("\tRule: " .. l_rule.left_child.rule .. " -> " .. r_rule.rule .. "\"\n")
        io.write("\t[label = " .. "\"KB2 " .. l_rule.rule .. " -> " .. r_rule.rule .. "\"];\n")
        res, bigger = check(l_rule.left_child, r_rule, rule, bigger, Constructors) 
    end
    if res == false then bigger = saved_bigger end
    if l_rule.right_child ~= nil and res ~= true then
        io.write("\"Order:\n")
        print_bigger(saved_bigger, Constructors)
        io.write("\tRule: " .. l_rule.rule .. " -> " .. r_rule.rule .. "\"\n")
        io.write("\t -> \n\"Order:\n")
        print_bigger(bigger, Constructors)
        io.write("\tRule: " .. l_rule.right_child.rule .. " -> " .. r_rule.rule .. "\"\n")
        io.write("\t[label = " .. "\"KB2 " .. l_rule.rule .. " -> " .. r_rule.rule .. "\"];\n")
        res, bigger = check(l_rule.right_child, r_rule, rule, bigger, Constructors) 
    end
    return res, bigger
end    

local function KB3(l_rule, r_rule, rule, bigger, Constructors)
    if string.sub(l_rule.rule, 1, 1) == string.sub(r_rule.rule, 1, 1) then return false, bigger end
    if #l_rule.rule== 1 then return false, bigger end
    if #r_rule.rule== 1 then return false, bigger end
    local res = false
    if findTableItem(string.sub(r_rule.rule, 1, 1), bigger[string.sub(l_rule.rule, 1, 1)].ch) then return true end
    local pos = #bigger[string.sub(l_rule.rule, 1, 1)].ch + 1
    local saved_bigger = saveBigger(bigger, Constructors)
    table.insert(bigger[string.sub(l_rule.rule, 1, 1)].ch, pos, string.sub(r_rule.rule, 1, 1))
    if check_bigger(bigger, Constructors) == false then return false, bigger end
    if r_rule.left_child ~= nil and r_rule.right_child ~= nil then
        io.write("\"Order:\n")
        print_bigger(saved_bigger, Constructors)
        io.write("\tRule: " .. l_rule.rule .. " -> " .. r_rule.rule .. "\"\n")
        io.write("\t -> \n\"Order:\n")
        print_bigger(bigger, Constructors)
        io.write("\tRule: " .. l_rule.rule .. " -> " .. r_rule.left_child.rule .. "\"\n")
        io.write("\t[label = " .. "\"KB3 " .. l_rule.rule .. " -> " .. r_rule.rule .. "\"];\n")
        res, bigger = check(l_rule, r_rule.left_child, rule, bigger, Constructors)
        if res == false then 
            return false, saved_bigger
        end
        io.write("\"Order:\n")
        print_bigger(saved_bigger, Constructors)
        io.write("\tRule: " .. l_rule.rule .. " -> " .. r_rule.rule .. "\"\n")
        io.write("\t -> \n\"Order:\n")
        print_bigger(bigger, Constructors)
        io.write("\tRule: " .. l_rule.rule .. " -> " .. r_rule.right_child.rule .. "\"\n")
        io.write("\t[label = " .. "\"KB3 " .. l_rule.rule .. " -> " .. r_rule.rule .. "\"];\n")
        res, bigger = check(l_rule, r_rule.right_child, rule, bigger, Constructors)
    elseif r_rule.left_child ~= nil then
        io.write("\"Order:\n")
        print_bigger(saved_bigger, Constructors)
        io.write("\tRule: " .. l_rule.rule .. " -> " .. r_rule.rule .. "\"\n")
        io.write("\t -> \n\"Order:\n")
        print_bigger(bigger, Constructors)
        io.write("\tRule: " .. l_rule.rule .. " -> " .. r_rule.left_child.rule .. "\"\n")
        io.write("\t[label = " .. "\"KB3 " .. l_rule.rule .. " -> " .. r_rule.rule .. "\"];\n")
        res, bigger = check(l_rule, r_rule.left_child, rule, bigger, Constructors) 
    else 
        error("Ahhh...")
    end
    return res, bigger
end

local function KB4(l_rule, r_rule, rule, bigger, Constructors)
    if string.sub(l_rule.rule, 1, 1) ~= string.sub(r_rule.rule, 1, 1) then return false, bigger end
    if #l_rule.rule == 1 then return false, bigger end
    local res, sus_bigger = check_lex(l_rule, r_rule, rule, bigger, Constructors)
    if res == false then return false, bigger end
    io.write("\"Order:\n")
    print_bigger(bigger, Constructors)
    io.write("\tRule: " .. l_rule.rule .. " -> " .. r_rule.rule .. "\"\n")
    io.write("\t -> \n\"Order:\n")
    print_bigger(sus_bigger, Constructors)
    io.write("\tRule: " .. l_rule.rule .. " -> " .. r_rule.rule .. "\"\n")
    io.write("\t[label = " .. "\"KB4 (with lex check) " .. l_rule.rule .. " -> " .. r_rule.rule .. "\"];\n")
    bigger = sus_bigger
    res = false
    local saved_bigger = saveBigger(bigger, Constructors)
    if r_rule.left_child ~= nil and r_rule.right_child ~= nil then
        io.write("\"Order:\n")
        print_bigger(saved_bigger, Constructors)
        io.write("\tRule: " .. l_rule.rule .. " -> " .. r_rule.rule .. "\"\n")
        io.write("\t -> \n\"Order:\n")
        print_bigger(bigger, Constructors)
        io.write("\tRule: " .. l_rule.rule .. " -> " .. r_rule.left_child.rule .. "\"\n")
        io.write("\t[label = " .. "\"KB4 " .. l_rule.rule .. " -> " .. r_rule.rule .. "\"];\n")
        res, bigger = check(l_rule, r_rule.left_child, rule, bigger, Constructors)
        if res == false then 
            return false, bigger
        end
        io.write("\"Order:\n")
        print_bigger(saved_bigger, Constructors)
        io.write("\tRule: " .. l_rule.rule .. " -> " .. r_rule.rule .. "\"\n")
        io.write("\t -> \n\"Order:\n")
        print_bigger(bigger, Constructors)
        io.write("\tRule: " .. l_rule.rule .. " -> " .. r_rule.right_child.rule .. "\"\n")
        io.write("\t[label = " .. "\"KB4 " .. l_rule.rule .. " -> " .. r_rule.rule .. "\"];\n")
        res, bigger = check(l_rule, r_rule.right_child, rule, bigger, Constructors) 
    elseif r_rule.left_child ~= nil then
        io.write("\"Order:\n")
        print_bigger(saved_bigger, Constructors)
        io.write("\tRule: " .. l_rule.rule .. " -> " .. r_rule.rule .. "\"\n")
        io.write("\t -> \n\"Order:\n")
        print_bigger(bigger, Constructors)
        io.write("\tRule: " .. l_rule.rule .. " -> " .. r_rule.left_child.rule .. "\"\n")
        io.write("\t[label = " .. "\"KB4 " .. l_rule.rule .. " -> " .. r_rule.rule .. "\"];\n")
        res, bigger = check(l_rule, r_rule.left_child, rule, bigger, Constructors) 
    else 
        error("Ahhh...")
    end
    return res, bigger
end

function check(l_rule, r_rule, rule, bigger, Constructors)
    if findTableItem(string.sub(r_rule.rule, 1, 1), bigger[string.sub(l_rule.rule, 1, 1)].ch) then
       local l =  #bigger[string.sub(l_rule.rule, 1, 1)].ch
       if ch ~= 0 then
        for i = 1, l, 1 do
            if bigger[string.sub(l_rule.rule, 1, 1)].ch[i] == string.sub(r_rule.rule, 1, 1) then
                return true, bigger
            end
        end
       end
    end
    if KB1(l_rule, r_rule) then return true, bigger end

    local save = saveBigger(bigger, Constructors)
    local res, sus_bigger = KB2(l_rule, r_rule, rule, bigger, Constructors)
    if res == true then return true, sus_bigger end

    local save2 = saveBigger(save, Constructors)
    local res, sus_bigger = KB4(l_rule, r_rule, rule, save, Constructors)
    if res == true then return true, sus_bigger end

    local res, sus_bigger = KB3(l_rule, r_rule, rule, save2, Constructors)
    if res == true then return true, sus_bigger end

    return false
end
local function merge_biggers(biggers, Constructors)
    local bigger = {}
    for i = 1, #Constructors, 1 do
        bigger[Constructors[i].ch] = {ch = {}}
    end

    for i = 1, #biggers, 1 do
        local l = 0
        for k = 1, #Constructors, 1 do
            for j = 1, #biggers[i][Constructors[k].ch].ch, 1 do
                if findTableItem(biggers[i][Constructors[k].ch].ch[j], bigger[Constructors[k].ch].ch) == false then
                    table.insert(bigger[Constructors[k].ch].ch, #bigger[Constructors[k].ch].ch + 1, biggers[i][Constructors[k].ch].ch[j])
                end
            end
        end
    end
    return bigger
end

function main()
    Order, Constructors, Rules = parser.parse("./tests/test2.txt")
    for i = 1, #Rules, 1 do
        parser.DrawTree(Rules[i])
    end
    local bigger = {}
    local lotof_bigger = {}
    local res = false
    for i = 1, #Constructors, 1 do
        bigger[Constructors[i].ch] = {ch = {}}
    end
    os.remove("out.txt")
    local file = io.open("out.txt", "a")
    io.output(file)
    
    for i=1, #Rules, 1 do
        io.write("digraph G {node [shape = box]\n")
        -- local bigger = {}
        -- for i = 1, #Constructors, 1 do
        --     bigger[Constructors[i].ch] = {ch = {}}
        -- end
        res, bigger = check(Rules[i].left_child, Rules[i].right_child, Rules[i], bigger, Constructors) 
        if res then
            local pos = #bigger[string.sub(Rules[i].left_child.rule, 1, 1)].ch + 1
            if res and parser.findConstructor(string.sub(Rules[i].right_child.rule, 1, 1), Constructors).n ~= 0 then 
                table.insert(bigger[string.sub(Rules[i].left_child.rule, 1, 1)].ch, pos, string.sub(Rules[i].right_child.rule, 1, 1)) 
            end
            -- table.insert(lotof_bigger, #lotof_bigger + 1, bigger)
        else io.write("}\n") break end 
        io.write("}\n")
    end
    table.insert(lotof_bigger, #lotof_bigger + 1, bigger)
    io.close(file)
    io.output(io.stdout)
    io.write("Результат:\n")
    if res then
        print_bigger(merge_biggers(lotof_bigger, Constructors), Constructors)
    else
        io.write("Не выходит\n")

    end
end

main()