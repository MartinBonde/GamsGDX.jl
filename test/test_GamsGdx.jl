using GamsGDX
using Test

file_path = "GamsGDX/test/test.gdx"

db = Gdx(file_path)

@testset "basic_access" begin
    @test db.qY == db[:qY]
    @test db.fp == db[:fp]
    # @test db.s_ == db[:s_]
end
