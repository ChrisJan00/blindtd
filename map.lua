Map={}
	
Map.hcells = 20
Map.vcells = 20

function examplemap()
local i,j
-- example: 10x10 map
-- closed: (cannot go through) 0
-- open: (can go through) 1
-- door open: 2
-- door closed: 3
-- door blocked: 4
for i=1,Map.hcells do
	Map[i]={}
  for j=1,Map.vcells do
	Map[i][j]={
		u = 0,
		d = 0,
		l = 0,
		r = 0,
		corridor = true
	}
  end
end

	Map[5][5].u = 1
	Map[5][4].d = 1
	Map[6][6].d = 2
	Map[6][7].u = 2
	Map[7][7].r = 3
	Map[8][7].l = 3
	Map[8][8].l = 4
	Map[8][7].r = 4
end

function drawmap(map)
	local i,j
	local dx=screensize[1]/Map.hcells
	local dy=screensize[2]/Map.vcells
	dx = dy
	for i=1,Map.hcells do
		for j=1,Map.vcells do
			if map[i][j].corridor then
				-- walls
				if map[i][j].u==0 then
					love.graphics.setColor(0,160,160)
					love.graphics.line((i-1)*dx,(j-1)*dy,i*dx,(j-1)*dy)
				end
				if map[i][j].l==0 then
					love.graphics.setColor(0,160,160)
					love.graphics.line((i-1)*dx,(j-1)*dy,(i-1)*dx,j*dy)
				end
				if map[i][j].d==0 then
					love.graphics.setColor(0,160,160)
					love.graphics.line((i-1)*dx,j*dy,i*dx,j*dy)
				end
				if map[i][j].r==0 then
					love.graphics.setColor(0,160,160)
					love.graphics.line(i*dx,(j-1)*dy,i*dx,j*dy)
				end
				
				-- closed doors
				if map[i][j].u==3 then
					love.graphics.setColor(160,0,160)
					love.graphics.line((i-1)*dx,(j-1)*dy,i*dx,(j-1)*dy)
				end
				if map[i][j].l==3 then
					love.graphics.setColor(160,0,160)
					love.graphics.line((i-1)*dx,(j-1)*dy,(i-1)*dx,j*dy)
				end
				if map[i][j].d==3 then
					love.graphics.setColor(160,0,160)
					love.graphics.line((i-1)*dx,j*dy,i*dx,j*dy)
				end
				if map[i][j].r==3 then
					love.graphics.setColor(160,0,160)
					love.graphics.line(i*dx,(j-1)*dy,i*dx,j*dy)
				end
				
				-- blocked doors
				if map[i][j].u==4 then
					love.graphics.setColor(200,0,0)
					love.graphics.line((i-1)*dx,(j-1)*dy,i*dx,(j-1)*dy)
				end
				if map[i][j].l==4 then
					love.graphics.setColor(200,0,0)
					love.graphics.line((i-1)*dx,(j-1)*dy,(i-1)*dx,j*dy)
				end
				if map[i][j].d==4 then
					love.graphics.setColor(200,0,0)
					love.graphics.line((i-1)*dx,j*dy,i*dx,j*dy)
				end
				if map[i][j].r==4 then
					love.graphics.setColor(200,0,0)
					love.graphics.line(i*dx,(j-1)*dy,i*dx,j*dy)
				end
				
				-- open doors
				if map[i][j].u==2 then
					love.graphics.setColor(160,0,160)
					love.graphics.line((i-1)*dx,(j-1)*dy,(i-3/4)*dx,(j-1)*dy)
					love.graphics.line((i-1/4)*dx,(j-1)*dy,i*dx,(j-1)*dy)
				end
				if map[i][j].l==2 then
					love.graphics.setColor(160,0,160)
					love.graphics.line((i-1)*dx,(j-1)*dy,(i-1)*dx,(j-3/4)*dy)
					love.graphics.line((i-1)*dx,(j-1/4)*dy,(i-1)*dx,j*dy)
				end
				if map[i][j].d==2 then
					love.graphics.setColor(160,0,160)
					love.graphics.line((i-1)*dx,j*dy,(i-3/4)*dx,j*dy)
					love.graphics.line((i-1/4)*dx,j*dy,i*dx,j*dy)
				end
				if map[i][j].r==2 then
					love.graphics.setColor(160,0,160)
					love.graphics.line(i*dx,(j-1)*dy,i*dx,(j-3/4)*dy)
					love.graphics.line(i*dx,(j-1/4)*dy,i*dx,j*dy)
				end
			end
		end
	end
end
