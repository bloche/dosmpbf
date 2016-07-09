/**
 * OSM PBF proto buffer definitions:
 * http://wiki.openstreetmap.org/wiki/PBF_Format
 * https://github.com/scrosby/OSM-binary/tree/master/src
 */

module dosmpbf.proto;

import dproto.dproto;

// osm pbf file format protocol buffer
enum fileFormat_proto = q{

    message BlobHeader {
        required string type = 1;
        optional bytes indexdata = 2;
        required int32 datasize = 3;
    }

    message Blob {
        optional bytes raw = 1; // No compression
        optional int32 raw_size = 2; // When compressed, the uncompressed size

        // Possible compressed versions of the data.
        optional bytes zlib_data = 3;

        // PROPOSED feature for LZMA compressed data. SUPPORT IS NOT REQUIRED.
        optional bytes lzma_data = 4;

        // Formerly used for bzip2 compressed data. Depreciated in 2010.
        optional bytes OBSOLETE_bzip2_data = 5 [deprecated=true]; // Don't reuse this tag number.
    }

};
mixin ProtocolBufferFromString!fileFormat_proto;

// osm pbf format protocol buffer
enum osmFormat_proto = q{

    message HeaderBlock {
        optional HeaderBBox bbox = 1;
        /* Additional tags to aid in parsing this dataset */
        repeated string required_features = 4;
        repeated string optional_features = 5;

        optional string writingprogram = 16;
        optional string source = 17; // From the bbox field.

        /* Tags that allow continuing an Osmosis replication */

        // replication timestamp, expressed in seconds since the epoch,
        // otherwise the same value as in the 'timestamp=...' field
        // in the state.txt file used by Osmosis
        optional int64 osmosis_replication_timestamp = 32;

        // replication sequence number (sequenceNumber in state.txt)
        optional int64 osmosis_replication_sequence_number = 33;

        // replication base URL (from Osmosis' configuration.txt file)
        optional string osmosis_replication_base_url = 34;
    }

    message PrimitiveBlock {
        required StringTable stringtable = 1;
        repeated PrimitiveGroup primitivegroup = 2;

        // Granularity, units of nanodegrees, used to store coordinates in this block
        optional int32 granularity = 17 [default=100]; 

        // Offset value between the output coordinates coordinates and the granularity grid, in units of nanodegrees.
        optional int64 lat_offset = 19 [default=0];
        optional int64 lon_offset = 20 [default=0]; 

        // Granularity of dates, normally represented in units of milliseconds since the 1970 epoch.
        optional int32 date_granularity = 18 [default=1000]; 


        // Proposed extension:
        //optional BBox bbox = XX;
    }

    message PrimitiveGroup {
        repeated Node     nodes = 1;
        optional DenseNodes dense = 2;
        repeated Way      ways = 3;
        repeated Relation relations = 4;
        repeated ChangeSet changesets = 5;
    }

    message StringTable {
        repeated bytes s = 1;
    }

    // THIS IS STUB DESIGN FOR CHANGESETS. NOT USED RIGHT NOW.
    // TODO:    REMOVE THIS?
    message ChangeSet {
        required int64 id = 1;
       
        //// Parallel arrays.
        //repeated uint32 keys = 2 [packed = true]; // String IDs.
        //repeated uint32 vals = 3 [packed = true]; // String IDs.

        //optional Info info = 4;

        //optional int64 created_at = 8;
        //optional int64 closetime_delta = 9;
        //optional bool open = 10;
        //optional HeaderBBox bbox = 11;
    }

    message HeaderBBox {
        required sint64 left = 1;
        required sint64 right = 2;
        required sint64 top = 3;
        required sint64 bottom = 4;
    }

    message Node {
        required sint64 id = 1;
        // Parallel arrays.
        repeated uint32 keys = 2 [packed = true]; // String IDs.
        repeated uint32 vals = 3 [packed = true]; // String IDs.

        optional Info info = 4; // May be omitted in omitmeta
        
        required sint64 lat = 8;
        required sint64 lon = 9;
    }

    message Way {
        required int64 id = 1;
        // Parallel arrays.
        repeated uint32 keys = 2 [packed = true];
        repeated uint32 vals = 3 [packed = true];

        optional Info info = 4;

        repeated sint64 refs = 8 [packed = true];  // DELTA coded
    }

    message Relation {
        enum MemberType {
            NODE = 0;
            WAY = 1;
            RELATION = 2;
        } 

        required int64 id = 1;

        // Parallel arrays.
        repeated uint32 keys = 2 [packed = true];
        repeated uint32 vals = 3 [packed = true];

        optional Info info = 4;

        // Parallel arrays
        repeated int32 roles_sid = 8 [packed = true];
        repeated sint64 memids = 9 [packed = true]; // DELTA encoded
        repeated MemberType types = 10 [packed = true];
    }

    message Info {
        optional int32 versionNo = 1 [default = -1];
        optional int32 timestamp = 2;
        optional int64 changeset = 3;
        optional int32 uid = 4;
        optional int32 user_sid = 5; // String IDs

        // The visible flag is used to store history information. It indicates that
        // the current object version has been created by a delete operation on the
        // OSM API.
        // When a writer sets this flag, it MUST add a required_features tag with
        // value 'HistoricalInformation' to the HeaderBlock.
        // If this flag is not available for some object it MUST be assumed to be
        // true if the file has the required_features tag 'HistoricalInformation'
        // set.
        optional bool visible = 6;
    }

    message DenseNodes {
        repeated sint64 id = 1 [packed = true]; // DELTA coded

        //repeated Info info = 4;
        optional DenseInfo denseinfo = 5;

        repeated sint64 lat = 8 [packed = true]; // DELTA coded
        repeated sint64 lon = 9 [packed = true]; // DELTA coded

        // Special packing of keys and vals into one array. May be empty if all nodes in this block are tagless.
        repeated int32 keys_vals = 10 [packed = true]; 
    }

    message OtherMessage {
        required int32 id = 1;
    }

    message DenseInfo {
        repeated int32 versionNo = 1 [packed = true]; 
        repeated sint64 timestamp = 2 [packed = true]; // DELTA coded
        repeated sint64 changeset = 3 [packed = true]; // DELTA coded
        repeated sint32 uid = 4 [packed = true]; // DELTA coded
        repeated sint32 user_sid = 5 [packed = true]; // String IDs for usernames. DELTA coded

        // The visible flag is used to store history information. It indicates that
        // the current object version has been created by a delete operation on the
        // OSM API.
        // When a writer sets this flag, it MUST add a required_features tag with
        // value 'HistoricalInformation' to the HeaderBlock.
        // If this flag is not available for some object it MUST be assumed to be
        // true if the file has the required_features tag 'HistoricalInformation'
        // set.
        repeated bool visible = 6 [packed = true];
    }

};
mixin ProtocolBufferFromString!osmFormat_proto;


unittest
{
    BlobHeader blobHeader;

    blobHeader.type = "exType";
    blobHeader.indexdata = cast(ubyte[])"exIdxData";
    blobHeader.datasize = 100;
    
    auto bh = blobHeader.serialize();
    blobHeader = BlobHeader(bh);

    assert(blobHeader.type == "exType");
    assert(blobHeader.indexdata == "exIdxData");
    assert(blobHeader.datasize == 100);

    
    Blob blob;

    blob.raw = cast(ubyte[])"exRaw";
    blob.raw_size = 5;
    blob.zlib_data = cast(ubyte[])"exZlibData";
    blob.lzma_data = cast(ubyte[])"exLzmaData";
    blob.OBSOLETE_bzip2_data = cast(ubyte[])"exBzip2Data";

    auto b = blob.serialize();
    blob = Blob(b);

    assert(blob.raw == "exRaw");
    assert(blob.raw_size == 5);
    assert(blob.zlib_data == "exZlibData");
    assert(blob.lzma_data == "exLzmaData");
    assert(blob.OBSOLETE_bzip2_data == "exBzip2Data");
    
    
    HeaderBBox headerBBox;

    headerBBox.left = 10;
    headerBBox.right = 5;
    headerBBox.top = -32;
    headerBBox.bottom = -24;

    auto hbb = headerBBox.serialize();
    headerBBox = HeaderBBox(hbb);

    assert(headerBBox.left == 10);
    assert(headerBBox.right == 5);
    assert(headerBBox.top == -32);
    assert(headerBBox.bottom == -24);


    HeaderBlock headerBlock;

    headerBlock.bbox = headerBBox;
    headerBlock.required_features = ["exReqFeatures"];
    headerBlock.optional_features = ["exOptionalFeatures"];
    headerBlock.writingprogram = "exWritingProgram";
    headerBlock.source = "exSource";
    headerBlock.osmosis_replication_timestamp = 12345;
    headerBlock.osmosis_replication_sequence_number = 54321;
    headerBlock.osmosis_replication_base_url = "http://example.com";

    auto hb = headerBlock.serialize();
    headerBlock = HeaderBlock(hb);

    assert(headerBlock.bbox == headerBBox);
    assert(headerBlock.required_features == ["exReqFeatures"]);
    assert(headerBlock.optional_features == ["exOptionalFeatures"]);
    assert(headerBlock.writingprogram == "exWritingProgram");
    assert(headerBlock.source == "exSource");
    assert(headerBlock.osmosis_replication_timestamp == 12345);
    assert(headerBlock.osmosis_replication_sequence_number == 54321);
    assert(headerBlock.osmosis_replication_base_url == "http://example.com");


    StringTable stringTable;

    stringTable.s = [cast(ubyte[])"exString"];

    auto s = stringTable.serialize();
    stringTable = StringTable(s);

    assert(stringTable.s == ["exString"]);


    ChangeSet changeSet;

    changeSet.id = 1234;

    auto cs = changeSet.serialize();
    changeSet = ChangeSet(s);

    assert(changeSet.id == 1234);


    Info info;

    info.versionNo = 1;
    info.timestamp = 234;
    info.changeset = 54321;
    info.uid = 4;
    info.user_sid = 5;
    info.visible = true;

    auto i = info.serialize();
    info = Info(i);

    assert(info.versionNo == 1);
    assert(info.timestamp == 234);
    assert(info.changeset == 54321);
    assert(info.uid == 4);
    assert(info.user_sid == 5);
    assert(info.visible == true);


    Node node;

    node.id = 1234;
    node.keys = [123, 456];
    node.vals = [234, 567];
    node.info = info;
    node.lat = 326;
    node.lon = -665;

    auto n = node.serialize();
    node = Node(n);

    assert(node.id == 1234);
    assert(node.keys == [123, 456]);
    assert(node.vals == [234, 567]);
    assert(node.info == info);
    assert(node.lat == 326);
    assert(node.lon == -665);


    Way way;

    way.id = 345;
    way.keys = [123, 234];
    way.vals = [567, 789];
    way.info = info;
    way.refs = [-234, 123];

    auto w = way.serialize();
    way = Way(w);

    assert(way.id == 345);
    assert(way.keys == [123, 234]);
    assert(way.vals == [567, 789]);
    assert(way.info == info);
    assert(way.refs == [-234, 123]);


    Relation relation;

    relation.id = 123;
    relation.keys = [123, 235];
    relation.vals = [456, 567];
    relation.info = info;
    relation.roles_sid = [1245];
    relation.memids = [-324];
    relation.types = [Relation.MemberType.NODE];

    auto r = relation.serialize();
    relation = Relation(r);

    assert(relation.id == 123);
    assert(relation.keys == [123, 235]);
    assert(relation.vals == [456, 567]);
    assert(relation.info == info);
    assert(relation.roles_sid == [1245]);
    assert(relation.memids == [-324]);
    assert(relation.types == [Relation.MemberType.NODE]); 


    DenseInfo denseInfo;

    denseInfo.versionNo = [123];
    denseInfo.timestamp = [-2345];
    denseInfo.changeset = [39045];
    denseInfo.uid = [34353];
    denseInfo.user_sid = [5432];
    denseInfo.visible = [true];

    auto di = denseInfo.serialize();
    denseInfo = DenseInfo(di);

    assert(denseInfo.versionNo == [123]);
    assert(denseInfo.timestamp == [-2345]);
    assert(denseInfo.changeset == [39045]);
    assert(denseInfo.uid == [34353]);
    assert(denseInfo.user_sid == [5432]);
    assert(denseInfo.visible == [true]); 


    DenseNodes denseNodes;

    denseNodes.id = [1234];
    denseNodes.denseinfo = denseInfo;
    denseNodes.lat = [-1345];
    denseNodes.lon = [343];
    denseNodes.keys_vals = [432];

    auto dn = denseNodes.serialize();
    denseNodes = DenseNodes(dn);

    assert(denseNodes.id == [1234]);
    assert(denseNodes.denseinfo == denseInfo);
    assert(denseNodes.lat == [-1345]);
    assert(denseNodes.lon == [343]);
    assert(denseNodes.keys_vals == [432]);


    PrimitiveGroup primitiveGroup;

    primitiveGroup.nodes = [node];
    primitiveGroup.dense = denseNodes;
    primitiveGroup.ways = [way];
    primitiveGroup.relations = [relation];
    primitiveGroup.changesets = [changeSet];

    auto pg = primitiveGroup.serialize();
    primitiveGroup = PrimitiveGroup(pg);

    assert(primitiveGroup.nodes == [node]);
    assert(primitiveGroup.dense == denseNodes);
    assert(primitiveGroup.ways == [way]);
    assert(primitiveGroup.relations == [relation]);
    assert(primitiveGroup.changesets == [changeSet]); 


    PrimitiveBlock primitiveBlock;

    primitiveBlock.stringtable = stringTable;
    primitiveBlock.primitivegroup = primitiveGroup;
    primitiveBlock.granularity = 435;
    primitiveBlock.lat_offset = 44;
    primitiveBlock.lon_offset = 32;
    primitiveBlock.date_granularity = 11;

    auto pb = primitiveBlock.serialize();
    primitiveBlock = PrimitiveBlock(pb);

    assert(primitiveBlock.stringtable == stringTable);
    assert(primitiveBlock.primitivegroup == primitiveGroup);
    assert(primitiveBlock.granularity == 435);
    assert(primitiveBlock.lat_offset == 44);
    assert(primitiveBlock.lon_offset == 32);
    assert(primitiveBlock.date_granularity == 11);


    OtherMessage otherMessage;

    otherMessage.id = 24;

    auto om = otherMessage.serialize();
    otherMessage = OtherMessage(om);

    assert(otherMessage.id == 24);
} // unittest