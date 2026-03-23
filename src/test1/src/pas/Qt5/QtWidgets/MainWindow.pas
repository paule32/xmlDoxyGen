unit MainWindow;

interface

type
    (**
     * \brief This is class QMainWindow.
     * \since version 5
     *)
    QMainWindow = class(QObject)
    public
        constructor Create;
        destructor Destroy; overwrite;
    end;

implementation

end.
