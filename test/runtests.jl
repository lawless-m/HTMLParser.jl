using Test, HTMLParser

@testset "HTMLParser" begin
	@test length(HTMLParser.HTML("<html><body><p>hello from <b>Julia</b></p></body></html>").blks) == 10
end


