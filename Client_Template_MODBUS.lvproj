<?xml version='1.0' encoding='UTF-8'?>
<Project Type="Project" LVVersion="25008000">
	<Property Name="NI.LV.All.SaveVersion" Type="Str">25.0</Property>
	<Property Name="NI.LV.All.SourceOnly" Type="Bool">true</Property>
	<Item Name="My Computer" Type="My Computer">
		<Property Name="NI.SortType" Type="Int">3</Property>
		<Property Name="server.app.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="server.control.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="server.tcp.enabled" Type="Bool">false</Property>
		<Property Name="server.tcp.port" Type="Int">0</Property>
		<Property Name="server.tcp.serviceName" Type="Str">My Computer/VI Server</Property>
		<Property Name="server.tcp.serviceName.default" Type="Str">My Computer/VI Server</Property>
		<Property Name="server.vi.callsEnabled" Type="Bool">true</Property>
		<Property Name="server.vi.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="specify.custom.address" Type="Bool">false</Property>
		<Item Name="subVIs" Type="Folder">
			<Item Name="AnalogInput.vi" Type="VI" URL="../subVIs/AnalogInput.vi"/>
			<Item Name="AnalogOutput.vi" Type="VI" URL="../subVIs/AnalogOutput.vi"/>
			<Item Name="ConnectToPannelAddressSpace.vi" Type="VI" URL="../subVIs/ConnectToPannelAddressSpace.vi"/>
			<Item Name="DigitalInput.vi" Type="VI" URL="../subVIs/DigitalInput.vi"/>
			<Item Name="DigitalOutput.vi" Type="VI" URL="../subVIs/DigitalOutput.vi"/>
			<Item Name="DisconnectFromPannelAddressSpace.vi" Type="VI" URL="../subVIs/DisconnectFromPannelAddressSpace.vi"/>
			<Item Name="MaintainConnectionToPannelAddressSpace.vi" Type="VI" URL="../subVIs/MaintainConnectionToPannelAddressSpace.vi"/>
			<Item Name="ReadFromPannelAddressSpace.vi" Type="VI" URL="../subVIs/ReadFromPannelAddressSpace.vi"/>
			<Item Name="TimeKeeping.vi" Type="VI" URL="../subVIs/TimeKeeping.vi"/>
			<Item Name="WriteToPannelAddressSpace.vi" Type="VI" URL="../subVIs/WriteToPannelAddressSpace.vi"/>
			<Item Name="arbitrarySessionLogging.vi" Type="VI" URL="../subVIs/arbitrarySessionLogging.vi"/>
			<Item Name="FieldPost.vi" Type="VI" URL="../subVIs/FieldPost.vi"/>
		</Item>
		<Item Name="Client_Template_MOD.vi" Type="VI" URL="../Client_Template_MOD.vi"/>
		<Item Name="Dependencies" Type="Dependencies"/>
		<Item Name="Build Specifications" Type="Build"/>
	</Item>
</Project>
