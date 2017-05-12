using System;
using System.Drawing;
using System.Collections;
using System.ComponentModel;
using System.Windows.Forms;
using System.Data;

namespace ActAccPlaypen
{
	/// <summary>
	/// Summary description for Form1.
	/// </summary>
	public class Form1 : System.Windows.Forms.Form
	{
		private System.Windows.Forms.Label label1;
		private System.Windows.Forms.TextBox textBox1;
		private System.Windows.Forms.CheckBox checkBox1;
		private System.Windows.Forms.Button button1;
		private System.Windows.Forms.MainMenu mainMenu1;
		private System.Windows.Forms.MenuItem menuItem1;
		private System.Windows.Forms.MenuItem menuItem2;
		private System.Windows.Forms.MenuItem menuItem3;
		private System.Windows.Forms.MenuItem menuItem4;
		private System.Windows.Forms.MenuItem menuItem5;
		private System.Windows.Forms.MenuItem menuItem6;
		private System.Windows.Forms.MenuItem menuItem7;
		private System.Windows.Forms.MenuItem menuItem8;
		private System.Windows.Forms.MenuItem menuItem9;
		private System.Windows.Forms.MenuItem menuItem10;
		private System.Windows.Forms.MenuItem menuItem11;
		private System.Windows.Forms.MenuItem menuItem12;
		private System.Windows.Forms.MenuItem menuItem13;
		private System.Windows.Forms.MenuItem menuItem14;
		private System.Windows.Forms.MenuItem menuItem15;
		private System.Windows.Forms.MenuItem menuItem16;
		private System.Windows.Forms.MenuItem menuItem17;
		private System.Windows.Forms.MenuItem menuItem18;
		private System.Windows.Forms.MenuItem menuItem19;
		private System.Windows.Forms.MenuItem menuItem20;
		private System.Windows.Forms.RadioButton Red;
		private System.Windows.Forms.RadioButton radioButton1;
		private System.Windows.Forms.RadioButton radioButton2;
		private System.Windows.Forms.GroupBox groupBox1;
		private System.Windows.Forms.TabControl tabControl1;
		private System.Windows.Forms.TabPage tabPage1;
		private System.Windows.Forms.TabPage tabPage2;
		private System.Windows.Forms.ListBox listBox1;
		private System.Windows.Forms.CheckedListBox checkedListBox1;
		private System.Windows.Forms.ListView listView1;
		private System.Windows.Forms.DomainUpDown domainUpDown1;
		private System.Windows.Forms.Label label2;
		private System.Windows.Forms.ColumnHeader columnHeader1;
		private System.Windows.Forms.ColumnHeader columnHeader2;
		private System.Windows.Forms.StatusBar statusBar1;
		private System.Windows.Forms.TreeView treeView1;
		private System.Windows.Forms.Label label3;
		private System.Windows.Forms.Label label4;
		private System.Windows.Forms.Label label5;
        private System.Windows.Forms.ContextMenu contextMenu1;
        private System.Windows.Forms.MenuItem menuItem21;
        private System.Windows.Forms.MenuItem menuItem22;
        private System.Windows.Forms.MenuItem menuItem23;
        private System.Windows.Forms.MenuItem menuItem24;
        private System.Windows.Forms.GroupBox groupBoxHollow;
		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.Container components = null;

		public Form1()
		{
			//
			// Required for Windows Form Designer support
			//
			InitializeComponent();

			//
			// TODO: Add any constructor code after InitializeComponent call
			//
		}

		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		protected override void Dispose( bool disposing )
		{
			if( disposing )
			{
				if (components != null) 
				{
					components.Dispose();
				}
			}
			base.Dispose( disposing );
		}

		#region Windows Form Designer generated code
		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		private void InitializeComponent()
		{
            System.Windows.Forms.ListViewItem listViewItem1 = new System.Windows.Forms.ListViewItem(new System.Windows.Forms.ListViewItem.ListViewSubItem[] {
                                                                                                                                                                new System.Windows.Forms.ListViewItem.ListViewSubItem(null, "Allamakee", System.Drawing.SystemColors.WindowText, System.Drawing.SystemColors.Window, new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)))),
                                                                                                                                                                new System.Windows.Forms.ListViewItem.ListViewSubItem(null, "15")}, -1);
            System.Windows.Forms.ListViewItem listViewItem2 = new System.Windows.Forms.ListViewItem(new System.Windows.Forms.ListViewItem.ListViewSubItem[] {
                                                                                                                                                                new System.Windows.Forms.ListViewItem.ListViewSubItem(null, "Adams", System.Drawing.SystemColors.WindowText, System.Drawing.SystemColors.Window, new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)))),
                                                                                                                                                                new System.Windows.Forms.ListViewItem.ListViewSubItem(null, "30")}, -1);
            System.Windows.Forms.ListViewItem listViewItem3 = new System.Windows.Forms.ListViewItem(new System.Windows.Forms.ListViewItem.ListViewSubItem[] {
                                                                                                                                                                new System.Windows.Forms.ListViewItem.ListViewSubItem(null, "Benton", System.Drawing.SystemColors.WindowText, System.Drawing.SystemColors.Window, new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)))),
                                                                                                                                                                new System.Windows.Forms.ListViewItem.ListViewSubItem(null, "45")}, -1);
            this.label1 = new System.Windows.Forms.Label();
            this.textBox1 = new System.Windows.Forms.TextBox();
            this.checkBox1 = new System.Windows.Forms.CheckBox();
            this.button1 = new System.Windows.Forms.Button();
            this.mainMenu1 = new System.Windows.Forms.MainMenu();
            this.menuItem1 = new System.Windows.Forms.MenuItem();
            this.menuItem5 = new System.Windows.Forms.MenuItem();
            this.menuItem6 = new System.Windows.Forms.MenuItem();
            this.menuItem7 = new System.Windows.Forms.MenuItem();
            this.menuItem8 = new System.Windows.Forms.MenuItem();
            this.menuItem9 = new System.Windows.Forms.MenuItem();
            this.menuItem10 = new System.Windows.Forms.MenuItem();
            this.menuItem2 = new System.Windows.Forms.MenuItem();
            this.menuItem11 = new System.Windows.Forms.MenuItem();
            this.menuItem12 = new System.Windows.Forms.MenuItem();
            this.menuItem3 = new System.Windows.Forms.MenuItem();
            this.menuItem13 = new System.Windows.Forms.MenuItem();
            this.menuItem14 = new System.Windows.Forms.MenuItem();
            this.menuItem15 = new System.Windows.Forms.MenuItem();
            this.menuItem16 = new System.Windows.Forms.MenuItem();
            this.menuItem19 = new System.Windows.Forms.MenuItem();
            this.menuItem20 = new System.Windows.Forms.MenuItem();
            this.menuItem4 = new System.Windows.Forms.MenuItem();
            this.menuItem17 = new System.Windows.Forms.MenuItem();
            this.menuItem18 = new System.Windows.Forms.MenuItem();
            this.Red = new System.Windows.Forms.RadioButton();
            this.radioButton1 = new System.Windows.Forms.RadioButton();
            this.radioButton2 = new System.Windows.Forms.RadioButton();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.tabControl1 = new System.Windows.Forms.TabControl();
            this.tabPage1 = new System.Windows.Forms.TabPage();
            this.label3 = new System.Windows.Forms.Label();
            this.listView1 = new System.Windows.Forms.ListView();
            this.columnHeader1 = new System.Windows.Forms.ColumnHeader();
            this.columnHeader2 = new System.Windows.Forms.ColumnHeader();
            this.checkedListBox1 = new System.Windows.Forms.CheckedListBox();
            this.listBox1 = new System.Windows.Forms.ListBox();
            this.label4 = new System.Windows.Forms.Label();
            this.label5 = new System.Windows.Forms.Label();
            this.tabPage2 = new System.Windows.Forms.TabPage();
            this.treeView1 = new System.Windows.Forms.TreeView();
            this.domainUpDown1 = new System.Windows.Forms.DomainUpDown();
            this.label2 = new System.Windows.Forms.Label();
            this.statusBar1 = new System.Windows.Forms.StatusBar();
            this.contextMenu1 = new System.Windows.Forms.ContextMenu();
            this.menuItem21 = new System.Windows.Forms.MenuItem();
            this.menuItem22 = new System.Windows.Forms.MenuItem();
            this.menuItem23 = new System.Windows.Forms.MenuItem();
            this.menuItem24 = new System.Windows.Forms.MenuItem();
            this.groupBoxHollow = new System.Windows.Forms.GroupBox();
            this.tabControl1.SuspendLayout();
            this.tabPage1.SuspendLayout();
            this.tabPage2.SuspendLayout();
            this.SuspendLayout();
            // 
            // label1
            // 
            this.label1.Location = new System.Drawing.Point(16, 24);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(56, 16);
            this.label1.TabIndex = 0;
            this.label1.Text = "Penguins";
            // 
            // textBox1
            // 
            this.textBox1.Location = new System.Drawing.Point(80, 24);
            this.textBox1.Name = "textBox1";
            this.textBox1.Size = new System.Drawing.Size(72, 20);
            this.textBox1.TabIndex = 1;
            this.textBox1.Text = "textBox1";
            // 
            // checkBox1
            // 
            this.checkBox1.Location = new System.Drawing.Point(168, 24);
            this.checkBox1.Name = "checkBox1";
            this.checkBox1.Size = new System.Drawing.Size(88, 16);
            this.checkBox1.TabIndex = 2;
            this.checkBox1.Text = "Left-handed";
            // 
            // button1
            // 
            this.button1.Location = new System.Drawing.Point(400, 296);
            this.button1.Name = "button1";
            this.button1.Size = new System.Drawing.Size(80, 24);
            this.button1.TabIndex = 10;
            this.button1.Text = "OK";
            this.button1.Click += new System.EventHandler(this.button1_Click);
            // 
            // mainMenu1
            // 
            this.mainMenu1.MenuItems.AddRange(new System.Windows.Forms.MenuItem[] {
                                                                                      this.menuItem1,
                                                                                      this.menuItem2,
                                                                                      this.menuItem3,
                                                                                      this.menuItem4});
            // 
            // menuItem1
            // 
            this.menuItem1.Index = 0;
            this.menuItem1.MenuItems.AddRange(new System.Windows.Forms.MenuItem[] {
                                                                                      this.menuItem5,
                                                                                      this.menuItem6,
                                                                                      this.menuItem7,
                                                                                      this.menuItem8,
                                                                                      this.menuItem9,
                                                                                      this.menuItem10});
            this.menuItem1.Text = "File";
            // 
            // menuItem5
            // 
            this.menuItem5.Index = 0;
            this.menuItem5.Text = "&New";
            // 
            // menuItem6
            // 
            this.menuItem6.Index = 1;
            this.menuItem6.Text = "&Open";
            // 
            // menuItem7
            // 
            this.menuItem7.Index = 2;
            this.menuItem7.Text = "Open &Halfway";
            // 
            // menuItem8
            // 
            this.menuItem8.Index = 3;
            this.menuItem8.Text = "&Close";
            // 
            // menuItem9
            // 
            this.menuItem9.Index = 4;
            this.menuItem9.Text = "&Mislay";
            // 
            // menuItem10
            // 
            this.menuItem10.Index = 5;
            this.menuItem10.Text = "E&xit";
            // 
            // menuItem2
            // 
            this.menuItem2.Index = 1;
            this.menuItem2.MenuItems.AddRange(new System.Windows.Forms.MenuItem[] {
                                                                                      this.menuItem11,
                                                                                      this.menuItem12});
            this.menuItem2.Text = "Edit";
            // 
            // menuItem11
            // 
            this.menuItem11.Index = 0;
            this.menuItem11.Text = "Red Pencil";
            // 
            // menuItem12
            // 
            this.menuItem12.Index = 1;
            this.menuItem12.Text = "Blue Pencil";
            // 
            // menuItem3
            // 
            this.menuItem3.Index = 2;
            this.menuItem3.MenuItems.AddRange(new System.Windows.Forms.MenuItem[] {
                                                                                      this.menuItem13,
                                                                                      this.menuItem14,
                                                                                      this.menuItem15,
                                                                                      this.menuItem16});
            this.menuItem3.Text = "View";
            // 
            // menuItem13
            // 
            this.menuItem13.Index = 0;
            this.menuItem13.Text = "Right-side up";
            // 
            // menuItem14
            // 
            this.menuItem14.Index = 1;
            this.menuItem14.Text = "Upside-down";
            // 
            // menuItem15
            // 
            this.menuItem15.Index = 2;
            this.menuItem15.Text = "Inside-out";
            // 
            // menuItem16
            // 
            this.menuItem16.Index = 3;
            this.menuItem16.MenuItems.AddRange(new System.Windows.Forms.MenuItem[] {
                                                                                       this.menuItem19,
                                                                                       this.menuItem20});
            this.menuItem16.Text = "Warped";
            // 
            // menuItem19
            // 
            this.menuItem19.Index = 0;
            this.menuItem19.Text = "Convex";
            // 
            // menuItem20
            // 
            this.menuItem20.Index = 1;
            this.menuItem20.Text = "Concave";
            // 
            // menuItem4
            // 
            this.menuItem4.Index = 3;
            this.menuItem4.MenuItems.AddRange(new System.Windows.Forms.MenuItem[] {
                                                                                      this.menuItem17,
                                                                                      this.menuItem18});
            this.menuItem4.Text = "Format";
            // 
            // menuItem17
            // 
            this.menuItem17.Index = 0;
            this.menuItem17.Text = "Tasteful";
            // 
            // menuItem18
            // 
            this.menuItem18.Index = 1;
            this.menuItem18.Text = "Tasteless";
            // 
            // Red
            // 
            this.Red.Location = new System.Drawing.Point(272, 24);
            this.Red.Name = "Red";
            this.Red.Size = new System.Drawing.Size(64, 16);
            this.Red.TabIndex = 4;
            this.Red.Text = "Red";
            // 
            // radioButton1
            // 
            this.radioButton1.Location = new System.Drawing.Point(272, 40);
            this.radioButton1.Name = "radioButton1";
            this.radioButton1.Size = new System.Drawing.Size(64, 16);
            this.radioButton1.TabIndex = 5;
            this.radioButton1.Text = "Blue";
            this.radioButton1.CheckedChanged += new System.EventHandler(this.radioButton1_CheckedChanged);
            // 
            // radioButton2
            // 
            this.radioButton2.Location = new System.Drawing.Point(272, 56);
            this.radioButton2.Name = "radioButton2";
            this.radioButton2.Size = new System.Drawing.Size(64, 16);
            this.radioButton2.TabIndex = 6;
            this.radioButton2.Text = "Green";
            // 
            // groupBox1
            // 
            this.groupBox1.Location = new System.Drawing.Point(256, 8);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(88, 72);
            this.groupBox1.TabIndex = 3;
            this.groupBox1.TabStop = false;
            this.groupBox1.Text = "Color";
            // 
            // tabControl1
            // 
            this.tabControl1.Controls.AddRange(new System.Windows.Forms.Control[] {
                                                                                      this.tabPage1,
                                                                                      this.tabPage2});
            this.tabControl1.Location = new System.Drawing.Point(24, 88);
            this.tabControl1.Name = "tabControl1";
            this.tabControl1.SelectedIndex = 0;
            this.tabControl1.Size = new System.Drawing.Size(408, 192);
            this.tabControl1.TabIndex = 9;
            // 
            // tabPage1
            // 
            this.tabPage1.Controls.AddRange(new System.Windows.Forms.Control[] {
                                                                                   this.label3,
                                                                                   this.listView1,
                                                                                   this.checkedListBox1,
                                                                                   this.listBox1,
                                                                                   this.label4,
                                                                                   this.label5});
            this.tabPage1.Location = new System.Drawing.Point(4, 22);
            this.tabPage1.Name = "tabPage1";
            this.tabPage1.Size = new System.Drawing.Size(400, 166);
            this.tabPage1.TabIndex = 0;
            this.tabPage1.Text = "List";
            // 
            // label3
            // 
            this.label3.Location = new System.Drawing.Point(32, 8);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(96, 16);
            this.label3.TabIndex = 0;
            this.label3.Text = "List box";
            // 
            // listView1
            // 
            this.listView1.Columns.AddRange(new System.Windows.Forms.ColumnHeader[] {
                                                                                        this.columnHeader1,
                                                                                        this.columnHeader2});
            this.listView1.Items.AddRange(new System.Windows.Forms.ListViewItem[] {
                                                                                      listViewItem1,
                                                                                      listViewItem2,
                                                                                      listViewItem3});
            this.listView1.Location = new System.Drawing.Point(256, 32);
            this.listView1.Name = "listView1";
            this.listView1.Size = new System.Drawing.Size(136, 80);
            this.listView1.TabIndex = 5;
            this.listView1.View = System.Windows.Forms.View.Details;
            // 
            // columnHeader1
            // 
            this.columnHeader1.Text = "County";
            // 
            // columnHeader2
            // 
            this.columnHeader2.Text = "Penguins";
            // 
            // checkedListBox1
            // 
            this.checkedListBox1.Items.AddRange(new object[] {
                                                                 "Adair",
                                                                 "Adams",
                                                                 "Allamakee",
                                                                 "Appanoose",
                                                                 "Audubon",
                                                                 "Benton",
                                                                 "Black Hawk",
                                                                 "Boone",
                                                                 "Bremer",
                                                                 "Buchanan",
                                                                 "Buena Vista",
                                                                 "Butler",
                                                                 "Calhoun",
                                                                 "Carroll",
                                                                 "Cass",
                                                                 "Cedar",
                                                                 "Cerro Gordo",
                                                                 "Cherokee",
                                                                 "Chickasaw",
                                                                 "Clarke",
                                                                 "Clay",
                                                                 "Clayton",
                                                                 "Clinton",
                                                                 "Crawford",
                                                                 "Dallas",
                                                                 "Davis",
                                                                 "Decatur",
                                                                 "Delaware",
                                                                 "Des Moines",
                                                                 "Dickinson",
                                                                 "Dubuque",
                                                                 "Emmet",
                                                                 "Fayette",
                                                                 "Floyd",
                                                                 "Franklin",
                                                                 "Fremont",
                                                                 "Greene",
                                                                 "Grundy",
                                                                 "Guthrie",
                                                                 "Hamilton",
                                                                 "Hancock",
                                                                 "Hardin",
                                                                 "Harrison",
                                                                 "Henry",
                                                                 "Howard",
                                                                 "Humboldt",
                                                                 "Ida",
                                                                 "Iowa",
                                                                 "Jackson",
                                                                 "Jasper",
                                                                 "Jefferson",
                                                                 "Johnson",
                                                                 "Jones",
                                                                 "Keokuk",
                                                                 "Kossuth",
                                                                 "Lee",
                                                                 "Linn",
                                                                 "Louisa",
                                                                 "Lucas",
                                                                 "Lyon",
                                                                 "Madison",
                                                                 "Mahaska",
                                                                 "Marion",
                                                                 "Marshall",
                                                                 "Mills",
                                                                 "Mitchell",
                                                                 "Monona",
                                                                 "Monroe",
                                                                 "Montgomery",
                                                                 "Muscatine",
                                                                 "O\'Brien",
                                                                 "Osceola",
                                                                 "Page",
                                                                 "Palo Alto",
                                                                 "Plymouth",
                                                                 "Pocahontas",
                                                                 "Polk",
                                                                 "Pottawattamie",
                                                                 "Poweshiek",
                                                                 "Ringgold",
                                                                 "Sac",
                                                                 "Scott",
                                                                 "Shelby",
                                                                 "Sioux",
                                                                 "Story",
                                                                 "Tama",
                                                                 "Taylor",
                                                                 "Union",
                                                                 "Van Buren",
                                                                 "Wapello",
                                                                 "Warren",
                                                                 "Washington",
                                                                 "Wayne",
                                                                 "Webster",
                                                                 "Winnebago",
                                                                 "Winneshiek",
                                                                 "Woodbury",
                                                                 "Worth",
                                                                 "Wright"});
            this.checkedListBox1.Location = new System.Drawing.Point(144, 32);
            this.checkedListBox1.Name = "checkedListBox1";
            this.checkedListBox1.Size = new System.Drawing.Size(96, 79);
            this.checkedListBox1.TabIndex = 3;
            // 
            // listBox1
            // 
            this.listBox1.Items.AddRange(new object[] {
                                                          "Adair",
                                                          "Adams",
                                                          "Allamakee",
                                                          "Appanoose",
                                                          "Audubon",
                                                          "Benton",
                                                          "Black Hawk",
                                                          "Boone",
                                                          "Bremer",
                                                          "Buchanan",
                                                          "Buena Vista",
                                                          "Butler",
                                                          "Calhoun",
                                                          "Carroll",
                                                          "Cass",
                                                          "Cedar",
                                                          "Cerro Gordo",
                                                          "Cherokee",
                                                          "Chickasaw",
                                                          "Clarke",
                                                          "Clay",
                                                          "Clayton",
                                                          "Clinton",
                                                          "Crawford",
                                                          "Dallas",
                                                          "Davis",
                                                          "Decatur",
                                                          "Delaware",
                                                          "Des Moines",
                                                          "Dickinson",
                                                          "Dubuque",
                                                          "Emmet",
                                                          "Fayette",
                                                          "Floyd",
                                                          "Franklin",
                                                          "Fremont",
                                                          "Greene",
                                                          "Grundy",
                                                          "Guthrie",
                                                          "Hamilton",
                                                          "Hancock",
                                                          "Hardin",
                                                          "Harrison",
                                                          "Henry",
                                                          "Howard",
                                                          "Humboldt",
                                                          "Ida",
                                                          "Iowa",
                                                          "Jackson",
                                                          "Jasper",
                                                          "Jefferson",
                                                          "Johnson",
                                                          "Jones",
                                                          "Keokuk",
                                                          "Kossuth",
                                                          "Lee",
                                                          "Linn",
                                                          "Louisa",
                                                          "Lucas",
                                                          "Lyon",
                                                          "Madison",
                                                          "Mahaska",
                                                          "Marion",
                                                          "Marshall",
                                                          "Mills",
                                                          "Mitchell",
                                                          "Monona",
                                                          "Monroe",
                                                          "Montgomery",
                                                          "Muscatine",
                                                          "O\'Brien",
                                                          "Osceola",
                                                          "Page",
                                                          "Palo Alto",
                                                          "Plymouth",
                                                          "Pocahontas",
                                                          "Polk",
                                                          "Pottawattamie",
                                                          "Poweshiek",
                                                          "Ringgold",
                                                          "Sac",
                                                          "Scott",
                                                          "Shelby",
                                                          "Sioux",
                                                          "Story",
                                                          "Tama",
                                                          "Taylor",
                                                          "Union",
                                                          "Van Buren",
                                                          "Wapello",
                                                          "Warren",
                                                          "Washington",
                                                          "Wayne",
                                                          "Webster",
                                                          "Winnebago",
                                                          "Winneshiek",
                                                          "Woodbury",
                                                          "Worth",
                                                          "Wright"});
            this.listBox1.Location = new System.Drawing.Point(32, 32);
            this.listBox1.Name = "listBox1";
            this.listBox1.Size = new System.Drawing.Size(104, 82);
            this.listBox1.TabIndex = 1;
            // 
            // label4
            // 
            this.label4.Location = new System.Drawing.Point(144, 8);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(96, 16);
            this.label4.TabIndex = 2;
            this.label4.Text = "Checklist box";
            this.label4.Click += new System.EventHandler(this.label4_Click);
            // 
            // label5
            // 
            this.label5.Location = new System.Drawing.Point(256, 8);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(96, 16);
            this.label5.TabIndex = 4;
            this.label5.Text = "List view";
            // 
            // tabPage2
            // 
            this.tabPage2.Controls.AddRange(new System.Windows.Forms.Control[] {
                                                                                   this.treeView1});
            this.tabPage2.Location = new System.Drawing.Point(4, 22);
            this.tabPage2.Name = "tabPage2";
            this.tabPage2.Size = new System.Drawing.Size(400, 166);
            this.tabPage2.TabIndex = 1;
            this.tabPage2.Text = "Tree";
            // 
            // treeView1
            // 
            this.treeView1.ImageIndex = -1;
            this.treeView1.Location = new System.Drawing.Point(24, 16);
            this.treeView1.Name = "treeView1";
            this.treeView1.Nodes.AddRange(new System.Windows.Forms.TreeNode[] {
                                                                                  new System.Windows.Forms.TreeNode("Stuff", new System.Windows.Forms.TreeNode[] {
                                                                                                                                                                     new System.Windows.Forms.TreeNode("Animal", new System.Windows.Forms.TreeNode[] {
                                                                                                                                                                                                                                                         new System.Windows.Forms.TreeNode("Mammals", new System.Windows.Forms.TreeNode[] {
                                                                                                                                                                                                                                                                                                                                              new System.Windows.Forms.TreeNode("Cats"),
                                                                                                                                                                                                                                                                                                                                              new System.Windows.Forms.TreeNode("Dogs", new System.Windows.Forms.TreeNode[] {
                                                                                                                                                                                                                                                                                                                                                                                                                                new System.Windows.Forms.TreeNode("Small"),
                                                                                                                                                                                                                                                                                                                                                                                                                                new System.Windows.Forms.TreeNode("Medium"),
                                                                                                                                                                                                                                                                                                                                                                                                                                new System.Windows.Forms.TreeNode("Large")})}),
                                                                                                                                                                                                                                                         new System.Windows.Forms.TreeNode("Arachnids")}),
                                                                                                                                                                     new System.Windows.Forms.TreeNode("Vegetable", new System.Windows.Forms.TreeNode[] {
                                                                                                                                                                                                                                                            new System.Windows.Forms.TreeNode("Pumpkin"),
                                                                                                                                                                                                                                                            new System.Windows.Forms.TreeNode("Peanut")}),
                                                                                                                                                                     new System.Windows.Forms.TreeNode("Mineral", new System.Windows.Forms.TreeNode[] {
                                                                                                                                                                                                                                                          new System.Windows.Forms.TreeNode("Multi-vitamins")}),
                                                                                                                                                                     new System.Windows.Forms.TreeNode("Ethereal", new System.Windows.Forms.TreeNode[] {
                                                                                                                                                                                                                                                           new System.Windows.Forms.TreeNode("Stuff on TV")})})});
            this.treeView1.SelectedImageIndex = -1;
            this.treeView1.Size = new System.Drawing.Size(360, 128);
            this.treeView1.TabIndex = 0;
            // 
            // domainUpDown1
            // 
            this.domainUpDown1.Items.Add("25");
            this.domainUpDown1.Items.Add("40");
            this.domainUpDown1.Items.Add("60");
            this.domainUpDown1.Items.Add("75");
            this.domainUpDown1.Items.Add("100");
            this.domainUpDown1.Items.Add("150");
            this.domainUpDown1.Items.Add("250");
            this.domainUpDown1.Location = new System.Drawing.Point(416, 16);
            this.domainUpDown1.Name = "domainUpDown1";
            this.domainUpDown1.Size = new System.Drawing.Size(72, 20);
            this.domainUpDown1.TabIndex = 8;
            this.domainUpDown1.Text = "domainUpDown1";
            // 
            // label2
            // 
            this.label2.Location = new System.Drawing.Point(376, 16);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(40, 16);
            this.label2.TabIndex = 7;
            this.label2.Text = "Watts";
            // 
            // statusBar1
            // 
            this.statusBar1.Location = new System.Drawing.Point(0, 336);
            this.statusBar1.Name = "statusBar1";
            this.statusBar1.Size = new System.Drawing.Size(504, 22);
            this.statusBar1.TabIndex = 11;
            this.statusBar1.Text = "Bankruptcy in progress";
            // 
            // contextMenu1
            // 
            this.contextMenu1.MenuItems.AddRange(new System.Windows.Forms.MenuItem[] {
                                                                                         this.menuItem21,
                                                                                         this.menuItem22,
                                                                                         this.menuItem23,
                                                                                         this.menuItem24});
            // 
            // menuItem21
            // 
            this.menuItem21.Index = 0;
            this.menuItem21.Text = "Fruitfly";
            // 
            // menuItem22
            // 
            this.menuItem22.Index = 1;
            this.menuItem22.Text = "Octosaurus";
            this.menuItem22.Click += new System.EventHandler(this.menuItem22_Click);
            // 
            // menuItem23
            // 
            this.menuItem23.Index = 2;
            this.menuItem23.Text = "Housecat";
            // 
            // menuItem24
            // 
            this.menuItem24.Index = 3;
            this.menuItem24.Text = "Toadstool";
            // 
            // groupBoxHollow
            // 
            this.groupBoxHollow.Location = new System.Drawing.Point(384, 48);
            this.groupBoxHollow.Name = "groupBoxHollow";
            this.groupBoxHollow.Size = new System.Drawing.Size(88, 32);
            this.groupBoxHollow.TabIndex = 12;
            this.groupBoxHollow.TabStop = false;
            this.groupBoxHollow.Text = "RightClickMe";
            // 
            // Form1
            // 
            this.AutoScaleBaseSize = new System.Drawing.Size(5, 13);
            this.ClientSize = new System.Drawing.Size(504, 358);
            this.ContextMenu = this.contextMenu1;
            this.Controls.AddRange(new System.Windows.Forms.Control[] {
                                                                          this.groupBoxHollow,
                                                                          this.statusBar1,
                                                                          this.domainUpDown1,
                                                                          this.tabControl1,
                                                                          this.Red,
                                                                          this.button1,
                                                                          this.checkBox1,
                                                                          this.textBox1,
                                                                          this.label1,
                                                                          this.radioButton1,
                                                                          this.radioButton2,
                                                                          this.groupBox1,
                                                                          this.label2});
            this.Menu = this.mainMenu1;
            this.Name = "Form1";
            this.Text = "ActAcc Playpen";
            this.Load += new System.EventHandler(this.Form1_Load);
            this.tabControl1.ResumeLayout(false);
            this.tabPage1.ResumeLayout(false);
            this.tabPage2.ResumeLayout(false);
            this.ResumeLayout(false);

        }
		#endregion

		/// <summary>
		/// The main entry point for the application.
		/// </summary>
		[STAThread]
		static void Main() 
		{
			Application.Run(new Form1());
		}

		private void radioButton1_CheckedChanged(object sender, System.EventArgs e)
		{
		
		}

		private void button1_Click(object sender, System.EventArgs e)
		{
			Close();
		}

		private void label4_Click(object sender, System.EventArgs e)
		{
		
		}

        private void Form1_Load(object sender, System.EventArgs e)
        {
        
        }

        private void menuItem22_Click(object sender, System.EventArgs e)
        {
            MessageBox.Show("Bankruptcy in progress", "Alert");
        }

	}
}
