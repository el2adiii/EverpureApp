import '../../../models/app_state_model.dart';

import './../../../blocs/orders_bloc.dart';
import 'package:flutter/material.dart';
import './../../../models/orders_model.dart';
import 'package:intl/intl.dart';
import 'order_detail.dart';

class OrderList extends StatefulWidget {

  AppStateModel appStateModel = AppStateModel();

  final ordersBloc = OrdersBloc();
  OrderList({Key key}) : super(key: key);
  @override
  _OrderListState createState() => _OrderListState();
}

class _OrderListState extends State<OrderList> {
  ScrollController _scrollController = new ScrollController();

  @override
  void initState() {
    super.initState();
    widget.ordersBloc.getOrders();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          widget.ordersBloc.hasMoreOrders) {
        widget.ordersBloc.loadMoreOrders();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1.0,
        title: Text(widget.appStateModel.blocks.localeText.orders),
      ),
      body: StreamBuilder(
          stream: widget.ordersBloc.allOrders,
          builder: (context, AsyncSnapshot<List<Order>> snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data.length == 0) {
                return Center(child: Text(widget.appStateModel.blocks.localeText.noOrders));
              } else {
                return CustomScrollView(
                  controller: _scrollController,
                  slivers: <Widget>[
                    buildList(snapshot),
                    buildLoadMore(),
                  ],
                );
              }
            } else {
              return Center(child: CircularProgressIndicator());
            }
          }),
    );
  }
  buildList(AsyncSnapshot<List<Order>> snapshot) {
    var formatter1 = new DateFormat('yyyy-MM-dd  hh:mm a');
    return SliverPadding(
      padding: EdgeInsets.all(8.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            final NumberFormat formatter = NumberFormat.currency(
                decimalDigits: snapshot.data[index].decimals, locale: Localizations.localeOf(context).toString(), name: snapshot.data[index].currency);
            return Card(
                elevation: 1.0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4.0),
                  onTap: () => openDetailPage(snapshot.data, index),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child:
                        ListTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(widget.appStateModel.blocks.localeText.order + '-' + snapshot.data[index].id.toString(), style: Theme.of(context).textTheme.subtitle,),
                                Text(formatter.format(
                                    double.parse(snapshot.data[index].total,)), style: Theme.of(context).textTheme.subtitle,),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                SizedBox(height: 5,),
                                Text(snapshot.data[index].status.toUpperCase()),
                                SizedBox(height: 5,),
                                Text(formatter1
                                    .format(snapshot.data[index].dateCreated)),
                              ],
                            )),
                  ),
                ));
          },
          childCount: snapshot.data.length,
        ),
      ),
    );
  }

  openDetailPage(List<Order> data, int index) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return OrderDetail(order: data[index]);
    }));
  }

  buildLoadMore() {
    return SliverPadding(
        padding: EdgeInsets.all(0.0),
        sliver: SliverList(
            delegate: SliverChildListDelegate([
          Container(
              height: 60,
              child: StreamBuilder(
                  stream: widget.ordersBloc.hasMoreOrderItems,
                  builder: (context, AsyncSnapshot<bool> snapshot) {
                    return snapshot.hasData && snapshot.data != false
                        ? Center(child: Text(widget.appStateModel.blocks.localeText.noMoreOrders+'!'))
                        : Center(child: CircularProgressIndicator());
                  }
                  //child: Center(child: CircularProgressIndicator())
                  ))
        ])));
  }
}
