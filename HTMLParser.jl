module HTMLParser
# a transliteration of 
# https://github.com/enthought/Python-2.7.3/blob/master/Lib/HTMLParser.py

export HTML, Block, StartTag, EndTag, Comment, Data, Script

abstract type Block end

struct StartTag <: Block
	name::String
	attrs #Dict{String, String}
end

struct EndTag <: Block
	name::String
end

struct Comment <: Block
	contents::String
end

struct Data <: Block
	data::String
end

struct Script <: Block
	code::String
end

function txt2attrs(at)
	attrs = Dict{String,String}()
	if length(at) == 1
		return attrs
	end
	
	function key_value(t)
		k = ""
		v = ""
		ks = 1
		t == "" && (return k, v, ks)
		
		# skip whitespace
		while ks < length(t) && t[ks] in [' ', '\n', '\r']
			ks += 1
		end
		# if end of string or terminator /
		if ks == length(t) || t[ks] == '/'
			return k, v, ks+1
		end
		
		# skip non whitespace (ignore invalid attribute name errors) 
		ke = ks+1
		while ke < length(t) && !(t[ke] in [' ', '=', '/', '\n', '\r'])
			ke += 1
		end
		
		
		# exit if at end of string or terminator / found (e.g. <option value="k" selected/>
		(ke == length(t)) && (return t[ks:ke], t[ks:ke], ke+1)
		
		k = t[ks:ke-1]		
		
		(t[ke] == '/') && (return k, k, ke+1)
		
		# skip whitespace
		vs = ke+1
		while vs < length(t) && t[vs] in [' ' '\n' '\r' '=']
			vs += 1
		end
		
		if t[vs] in ['"', '\'']
			delim = [t[vs]]
			vs += 1
			if t[vs] == t[vs-1]
				return k, v, vs+1
			end
		else
			delim = [' ' '/']
		end
		
		ve = vs+1
		while ve < length(t) && !(t[ve] in delim)
			ve += 1
		end

		if ve > length(t)
			v = t[vs:ve-1]
		else
			if t[ve] in delim || t[ve] == '/'
				v = t[vs:ve-1]
			else
				v = t[vs:ve]
			end
		end

		return k, v, ve+1
	end
	
	k, v, P = key_value(at[2])
	attrs[k] = v
	while P < at[2].endof
		k, v, p = key_value(at[2][P:end])
		attrs[k] = v
		P += p
	end
	
	attrs
end

struct HTML
	blks::Vector{Block}
	function HTML(raw::String)
		inscript = 0
		blks = Vector{Block}()
		
		lst = split(raw, '<', keep=false)
		for lt in lst
			
			# endtag
			if lt[1] == '/'
				bt = split(lt[2:end], '>')
				if inscript > 0
					if bt[1] == "script"
						push!(blks, Script(raw[inscript:bt[1].offset+7]))
						bt[2] != "" && push!(blks, Data(bt[2]))
						inscript = 0
					end
				else
					push!(blks, EndTag(bt[1]))
					bt[2] != "" && push!(blks, Data(bt[2]))
				end
				continue
			end
		
			# comment
			if length(lt) > 2 && lt[1:3] == "!--"
				bt = split(lt[4:end], '>')
				push!(blks, Comment(bt[1][1:end-3]))
				bt[2] != "" && push!(blks, Data(bt[2]))
				continue
			end
	
			inscript > 0 && continue
			
			# open tag

			bt = split(lt[1:end], '>')
			att = split(bt[1], ' ', limit=2)
			if att[1] == ""
				continue
			elseif att[1] == "script"
				inscript = att[1].offset
			elseif endswith(bt[end], "/")
				push!(blks, StartTag(att[1], txt2attrs(att)))
				push!(blks, EndTag(att[1]))
				length(bt) == 2 && bt[2] != "" && push!(blks, Data(bt[2]))
			else
				push!(blks, StartTag(att[1], txt2attrs(att)))
				length(bt) == 2 && bt[2] != "" && push!(blks, Data(bt[2]))
			end
		end
		new(blks)
	end
end


###
end
